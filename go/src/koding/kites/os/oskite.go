package main

import (
	"io"
	"io/ioutil"
	"koding/kites/os/ldapserver"
	"koding/tools/config"
	"koding/tools/db"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/tools/lifecycle"
	"koding/tools/log"
	"koding/tools/utils"
	"koding/virt"
	"labix.org/v2/mgo/bson"
	"net"
	"os"
	"os/signal"
	"strings"
	"sync"
	"syscall"
	"time"
)

type VMInfo struct {
	vmId          bson.ObjectId
	vmName        string
	channels      map[*kite.Channel]bool
	timeout       *time.Timer
	totalCpuUsage int

	State       string `json:"state"`
	CpuUsage    int    `json:"cpuUsage"`
	CpuShares   int    `json:"cpuShares"`
	MemoryUsage int    `json:"memoryUsage"`
	MemoryLimit int    `json:"memoryLimit"`
}

var infos = make(map[bson.ObjectId]*VMInfo)
var infosMutex sync.Mutex
var templateDir = config.Current.ProjectRoot + "/go/templates"

func main() {
	lifecycle.Startup("kite.os", true)
	if err := virt.LoadTemplates(templateDir); err != nil {
		log.LogError(err, 0)
		return
	}

	unprepareAll()

	go func() {
		sigtermChannel := make(chan os.Signal)
		signal.Notify(sigtermChannel, syscall.SIGTERM)
		<-sigtermChannel
		unprepareAll()
		log.SendLogsAndExit(0)
	}()

	go ldapserver.Listen()
	go LimiterLoop()
	k := kite.New("os")

	k.LoadBalancer = func(correlationName string, username string, deadService string) string {
		if deadService != "" {
			if _, err := db.VMs.UpdateAll(bson.M{"hostKite": deadService}, bson.M{"$set": bson.M{"hostKite": nil}}); err != nil {
				log.LogError(err, 0)
			}
		}

		var vm *virt.VM
		if bson.IsObjectIdHex(correlationName) {
			db.VMs.FindId(bson.ObjectIdHex(correlationName)).One(&vm)
		}
		if vm == nil {
			if err := db.VMs.Find(bson.M{"name": correlationName}).One(&vm); err != nil {
				return k.ServiceUniqueName
			}
		}

		if vm.HostKite == "" {
			return k.ServiceUniqueName
		}
		return vm.HostKite
	}

	registerVmMethod(k, "vm.start", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		if !vos.Permissions.Sudo {
			return nil, &kite.PermissionError{}
		}
		return vos.VM.Start()
	})

	registerVmMethod(k, "vm.shutdown", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		if !vos.Permissions.Sudo {
			return nil, &kite.PermissionError{}
		}
		return vos.VM.Shutdown()
	})

	registerVmMethod(k, "vm.stop", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		if !vos.Permissions.Sudo {
			return nil, &kite.PermissionError{}
		}
		return vos.VM.Stop()
	})

	registerVmMethod(k, "vm.reinitialize", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		if !vos.Permissions.Sudo {
			return nil, &kite.PermissionError{}
		}
		vos.VM.Prepare(getUsers(vos.VM), true)
		return vos.VM.Start()
	})

	registerVmMethod(k, "vm.info", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		info := infos[vos.VM.Id]
		info.State = vos.VM.GetState()
		return info, nil
	})

	registerVmMethod(k, "vm.createSnapshot", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		if !vos.Permissions.Sudo {
			return nil, &kite.PermissionError{}
		}

		snippet := virt.VM{
			Id:         bson.NewObjectId(),
			SnapshotOf: vos.VM.Id,
		}

		if err := vos.VM.CreateConsistentSnapshot(snippet.Id.Hex()); err != nil {
			return nil, err
		}

		if err := db.VMs.Insert(snippet); err != nil {
			return nil, err
		}

		return snippet.Id.Hex(), nil
	})

	registerVmMethod(k, "spawn", true, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		var command []string
		if args.Unmarshal(&command) != nil {
			return nil, &kite.ArgumentError{Expected: "array of strings"}
		}
		return vos.VM.AttachCommand(vos.User.Uid, "", command...).CombinedOutput()
	})

	registerVmMethod(k, "exec", true, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		var line string
		if args.Unmarshal(&line) != nil {
			return nil, &kite.ArgumentError{Expected: "string"}
		}
		return vos.VM.AttachCommand(vos.User.Uid, "", "/bin/bash", "-c", line).CombinedOutput()
	})

	registerFileSystemMethods(k)
	registerWebtermMethods(k)
	registerAppMethods(k)

	k.Run()
}

type VMNotFoundError struct {
	Name string
}

func (err *VMNotFoundError) Error() string {
	return "There is no VM with name/id '" + err.Name + "'."
}

func registerVmMethod(k *kite.Kite, method string, concurrent bool, callback func(*dnode.Partial, *kite.Channel, *virt.VOS) (interface{}, error)) {
	k.Handle(method, concurrent, func(args *dnode.Partial, channel *kite.Channel) (interface{}, error) {
		var user virt.User
		if err := db.Users.Find(bson.M{"username": channel.Username}).One(&user); err != nil {
			panic(err)
		}
		if user.Uid < virt.UserIdOffset {
			panic("User with too low uid.")
		}

		vm, _ := channel.KiteData.(*virt.VM)
		if vm != nil && !vm.IsTemporary() {
			if err := db.VMs.FindId(vm.Id).One(&vm); err != nil {
				return nil, &VMNotFoundError{Name: channel.CorrelationName}
			}

			permissions := vm.GetPermissions(&user)
			if vm.SnapshotOf == "" && permissions == nil {
				return nil, &kite.PermissionError{}
			}
		}
		if vm == nil {
			if bson.IsObjectIdHex(channel.CorrelationName) {
				db.VMs.FindId(bson.ObjectIdHex(channel.CorrelationName)).One(&vm)
			}
			if vm == nil {
				if err := db.VMs.Find(bson.M{"name": channel.CorrelationName}).One(&vm); err != nil {
					return nil, &VMNotFoundError{Name: channel.CorrelationName}
				}
			}

			if vm.HostKite != k.ServiceUniqueName {
				if err := db.VMs.Update(bson.M{"_id": vm.Id, "hostKite": nil}, bson.M{"$set": bson.M{"hostKite": k.ServiceUniqueName}}); err != nil {
					return nil, &kite.WrongChannelError{}
				}
				vm.HostKite = k.ServiceUniqueName
			}

			permissions := vm.GetPermissions(&user)
			if vm.SnapshotOf == "" && permissions == nil {
				return nil, &kite.PermissionError{}
			}

			if vm.SnapshotOf != "" {
				var err error
				vm, err = vm.CreateTemporaryVM()
				if err != nil {
					return nil, err
				}
			}

			channel.KiteData = vm
		}

		infosMutex.Lock()
		info, isExistingState := infos[vm.Id]
		if !isExistingState {
			info = newInfo(vm)
			infos[vm.Id] = info
		}
		if !info.channels[channel] {
			info.channels[channel] = true
			if info.timeout != nil {
				info.timeout.Stop()
				info.timeout = nil
			}

			channel.OnDisconnect(func() {
				infosMutex.Lock()
				defer infosMutex.Unlock()

				delete(info.channels, channel)
				if len(info.channels) == 0 {
					info.startTimeout()
				}
			})
		}
		infosMutex.Unlock()

		if vm.IP == nil {
			ipInt := db.NextCounterValue("vm_ip")
			ip := net.IPv4(byte(ipInt>>24), byte(ipInt>>16), byte(ipInt>>8), byte(ipInt))
			if !vm.IsTemporary() {
				if err := db.VMs.Update(bson.M{"_id": vm.Id, "ip": nil}, bson.M{"$set": bson.M{"ip": ip}}); err != nil {
					panic(err)
				}
			}
			vm.IP = ip
		}

		if vm.LdapPassword == "" {
			ldapPassword := utils.RandomString()
			if !vm.IsTemporary() {
				if err := db.VMs.Update(bson.M{"_id": vm.Id}, bson.M{"$set": bson.M{"ldapPassword": ldapPassword}}); err != nil {
					panic(err)
				}
			}
			vm.LdapPassword = ldapPassword
		}

		if _, err := os.Stat(vm.File("")); err != nil {
			if !os.IsNotExist(err) {
				panic(err)
			}

			vm.SetHostname(vm.Name + "." + config.Current.UserSitesDomain)
			vm.Prepare(getUsers(vm), false)
			if out, err := vm.Start(); err != nil {
				log.Err("Could not start VM.", err, out)
			}
			if out, err := vm.WaitForState("RUNNING", time.Second); err != nil {
				log.Warn("Waiting for VM startup failed.", err, out)
			}
		}

		rootVos, err := vm.OS(&virt.RootUser)
		if err != nil {
			panic(err)
		}
		userVos, err := vm.OS(&user)
		if err != nil {
			panic(err)
		}

		if !vm.IsTemporary() {
			if _, err := rootVos.Stat("/home/" + user.Name); err != nil {
				if !os.IsNotExist(err) {
					panic(err)
				}

				if err := rootVos.MkdirAll("/home/"+user.Name, 0755); err != nil && !os.IsExist(err) {
					panic(err)
				}
				if err := rootVos.Chown("/home/"+user.Name, user.Uid, user.Uid); err != nil {
					panic(err)
				}
				if err := copyIntoVos(templateDir+"/user", "/home/"+user.Name, userVos); err != nil {
					panic(err)
				}
			}

			start := strings.Index(vm.Name, "~") + 1
			end := strings.LastIndex(vm.Name, "-")
			if end == -1 {
				end = len(vm.Name)
			}
			vmHomeName := vm.Name[start:end]
			websiteDir := "/home/" + vmHomeName + "/Sites/" + vm.Hostname()
			if _, err := rootVos.Stat(websiteDir); err != nil {
				if !os.IsNotExist(err) {
					panic(err)
				}

				websiteVos := rootVos
				if vmHomeName == user.Name {
					websiteVos = userVos
				}
				if err := websiteVos.MkdirAll(websiteDir, 0755); err != nil {
					panic(err)
				}
				if err := copyIntoVos(templateDir+"/website", websiteDir, websiteVos); err != nil {
					panic(err)
				}
			}
			if _, err := rootVos.Stat("/etc/apache2"); err == nil {
				if _, err := rootVos.Stat("/etc/apache2/sites-available/" + vm.Hostname()); err != nil {
					if !os.IsNotExist(err) {
						panic(err)
					}

					file, err := rootVos.Create("/etc/apache2/sites-available/" + vm.Hostname())
					if err != nil {
						panic(err)
					}
					defer file.Close()
					if err := virt.Templates.ExecuteTemplate(file, "apache-site", vm); err != nil {
						panic(err)
					}

					if err := rootVos.Symlink("/etc/apache2/sites-available/"+vm.Hostname(), "/etc/apache2/sites-enabled/"+vm.Hostname()); err != nil && !os.IsExist(err) {
						panic(err)
					}
				}
			}

			if vmHomeName != user.Name {
				if err := userVos.Mkdir("/home/"+user.Name+"/Web", 0755); err != nil && !os.IsExist(err) {
					panic(err)
				}
				if err := rootVos.Symlink("/home/"+user.Name+"/Web", websiteDir+"/~"+user.Name); err != nil && !os.IsExist(err) {
					panic(err)
				}
			}
		}

		return callback(args, channel, userVos)
	})
}

func copyIntoVos(src, dst string, vos *virt.VOS) error {
	sf, err := os.Open(src)
	if err != nil {
		return err
	}
	defer sf.Close()

	fi, err := sf.Stat()
	if err != nil {
		return err
	}

	if fi.Name() == "empty-directory" {
		// ignored file
	} else if fi.IsDir() {
		if err := vos.Mkdir(dst, fi.Mode()); err != nil && !os.IsExist(err) {
			return err
		}

		entries, err := sf.Readdirnames(0)
		if err != nil {
			return err
		}
		for _, entry := range entries {
			if err := copyIntoVos(src+"/"+entry, dst+"/"+entry, vos); err != nil {
				return err
			}
		}
	} else {
		df, err := vos.OpenFile(dst, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, fi.Mode())
		if err != nil {
			return err
		}
		defer df.Close()

		if _, err := io.Copy(df, sf); err != nil {
			return err
		}
	}

	return nil
}

func getUsers(vm *virt.VM) []virt.User {
	users := make([]virt.User, len(vm.Users))
	for i, entry := range vm.Users {
		if err := db.Users.FindId(entry.Id).One(&users[i]); err != nil {
			panic(err)
		}
		if users[i].Uid == 0 {
			panic("User with uid 0.")
		}
	}
	return users
}

func newInfo(vm *virt.VM) *VMInfo {
	return &VMInfo{
		vmId:          vm.Id,
		vmName:        vm.String(),
		channels:      make(map[*kite.Channel]bool),
		totalCpuUsage: utils.MaxInt,
		CpuShares:     1000,
	}
}

func (info *VMInfo) startTimeout() {
	info.timeout = time.AfterFunc(10*time.Minute, func() {
		infosMutex.Lock()
		defer infosMutex.Unlock()

		if len(info.channels) != 0 {
			return
		}

		var vm virt.VM
		if err := db.VMs.FindId(info.vmId).One(&vm); err != nil {
			log.Err("Could not find VM for shutdown.", err)
		}
		if out, err := vm.Shutdown(); err != nil {
			log.Err("Could not shutdown VM.", err, out)
		}

		if err := vm.Unprepare(); err != nil {
			log.Warn(err.Error())
		}

		if !vm.IsTemporary() {
			if err := db.VMs.Update(bson.M{"_id": vm.Id}, bson.M{"$set": bson.M{"hostKite": nil}}); err != nil {
				log.LogError(err, 0)
			}
		}

		if vm.IsTemporary() {
			if err := vm.Destroy(); err != nil {
				log.Warn(err.Error())
			}
		}

		delete(infos, vm.Id)
	})
}

func unprepareAll() {
	dirs, err := ioutil.ReadDir("/var/lib/lxc")
	if err != nil {
		log.LogError(err, 0)
		return
	}
	for _, dir := range dirs {
		if strings.HasPrefix(dir.Name(), "vm-") {
			vm := virt.VM{Id: bson.ObjectIdHex(dir.Name()[3:])}
			if err := vm.Unprepare(); err != nil {
				log.Warn(err.Error())
			}
		}
	}
}
