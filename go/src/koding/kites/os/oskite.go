package main

import (
	"encoding/binary"
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
	mutex         sync.Mutex
	totalCpuUsage int

	State       string `json:"state"`
	CpuUsage    int    `json:"cpuUsage"`
	CpuShares   int    `json:"cpuShares"`
	MemoryUsage int    `json:"memoryUsage"`
	MemoryLimit int    `json:"memoryLimit"`
}

var infos = make(map[bson.ObjectId]*VMInfo)
var runningVmMethods = make(map[string]string)
var infosMutex sync.Mutex
var templateDir = config.Current.ProjectRoot + "/go/templates"
var firstContainerIP net.IP
var containerSubnet *net.IPNet
var ipCounterInitialValue int
var shutdownStarted bool
var shutdownMutex sync.Mutex

func main() {
	lifecycle.Startup("kite.os", true)

	var err error
	if firstContainerIP, containerSubnet, err = net.ParseCIDR(config.Current.ContainerSubnet); err != nil {
		log.LogError(err, 0)
		return
	}

	if err := virt.LoadTemplates(templateDir); err != nil {
		log.LogError(err, 0)
		return
	}
	unprepareAll()
	go func() {
		sigtermChannel := make(chan os.Signal)
		signal.Notify(sigtermChannel, syscall.SIGTERM)
		<-sigtermChannel
		shutdownMutex.Lock()
		shutdownStarted = true
		shutdownMutex.Unlock()
		// wait for the current running methods to return
		// we know newcoming methods will be thrown away thanks to
		// shutdownStarted variable
		for {
			if len(runningVmMethods) == 0 {
				break
			} else {
				time.Sleep(1 * time.Second)
			}
		}
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
			if err := db.VMs.Find(bson.M{"hostname": correlationName}).One(&vm); err != nil {
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
			return nil, &kite.ArgumentError{Expected: "[array of strings]"}
		}
		return vos.VM.AttachCommand(vos.User.Uid, "", command...).CombinedOutput()
	})

	registerVmMethod(k, "exec", true, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		var line string
		if args.Unmarshal(&line) != nil {
			return nil, &kite.ArgumentError{Expected: "[string]"}
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
	return "There is no VM with hostname/id '" + err.Name + "'."
}

func registerVmMethod(k *kite.Kite, method string, concurrent bool, callback func(*dnode.Partial, *kite.Channel, *virt.VOS) (interface{}, error)) {
	shutdownMutex.Lock()
	if shutdownStarted {
		log.Warn("Requests thrown away during shutdown.")
		return
	} else {
		myId := utils.RandomString()
		runningVmMethods[myId] = method
		defer func(id string) {
			delete(runningVmMethods, id)
		}(myId)
	}
	shutdownMutex.Unlock()
	k.Handle(method, concurrent, func(args *dnode.Partial, channel *kite.Channel) (methodReturnValue interface{}, methodError error) {
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
				if err := db.VMs.Find(bson.M{"hostname": channel.CorrelationName}).One(&vm); err != nil {
					return nil, &VMNotFoundError{Name: channel.CorrelationName}
				}
			}
			if k.ServiceUniqueName == "" {
				log.Warn("Service unique name is empty")
			}

			if vm.HostKite != k.ServiceUniqueName && k.ServiceUniqueName != "" {
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

		info.mutex.Lock()
		defer info.mutex.Unlock()

		defer func() {
			if err := recover(); err != nil {
				log.LogError(err, 1, channel.Username, channel.CorrelationName, vm.String())
				methodError = &kite.InternalKiteError{}
			}
		}()

		if vm.IP == nil {
			ipInt := db.NextCounterValue("vm_ip", int(binary.BigEndian.Uint32(firstContainerIP.To4())))
			ip := net.IPv4(byte(ipInt>>24), byte(ipInt>>16), byte(ipInt>>8), byte(ipInt))
			if !vm.IsTemporary() {
				if err := db.VMs.Update(bson.M{"_id": vm.Id, "ip": nil}, bson.M{"$set": bson.M{"ip": ip}}); err != nil {
					panic(err)
				}
			}
			vm.IP = ip
		}
		if !containerSubnet.Contains(vm.IP) {
			panic("VM with IP that is not in the container subnet: " + vm.IP.String())
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

			vmWebDir := "/home/" + vm.WebHome + "/Web"
			userWebDir := "/home/" + user.Name + "/Web"

			if err := rootVos.Symlink(vmWebDir, "/var/www"); err == nil {
				// symlink successfully created

				if _, err := rootVos.Stat(vmWebDir); err != nil {
					if !os.IsNotExist(err) {
						panic(err)
					}
					// vmWebDir directory does not yes exist

					vmWebVos := rootVos
					if vmWebDir == userWebDir {
						vmWebVos = userVos
					}

					// migration of old Sites directory
					migrationErr := vmWebVos.Rename("/home/"+vm.WebHome+"/Sites/"+vm.HostnameAlias, vmWebDir)
					vmWebVos.Remove("/home/" + vm.WebHome + "/Sites")
					rootVos.Remove("/etc/apache2/sites-enabled/" + vm.HostnameAlias)

					if migrationErr != nil {
						// create fresh Web directory if migration unsuccessful
						if err := vmWebVos.MkdirAll(vmWebDir, 0755); err != nil {
							panic(err)
						}
						if err := copyIntoVos(templateDir+"/website", vmWebDir, vmWebVos); err != nil {
							panic(err)
						}
					}
				}
			}

			if _, err := rootVos.Stat(userWebDir); err != nil && vmWebDir != userWebDir {
				if !os.IsNotExist(err) {
					panic(err)
				}
				// userWebDir directory does not yes exist

				if err := userVos.MkdirAll(userWebDir, 0755); err != nil {
					panic(err)
				}
				if err := copyIntoVos(templateDir+"/website", userWebDir, userVos); err != nil {
					panic(err)
				}
				if err := rootVos.Symlink(userWebDir, vmWebDir+"/~"+user.Name); err != nil && !os.IsExist(err) {
					panic(err)
				}
			}
		}

		if concurrent {
			info.mutex.Unlock()
			defer info.mutex.Lock()
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
