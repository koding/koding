package main

import (
	"encoding/binary"
	"errors"
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
	"labix.org/v2/mgo"
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
	useCounter    int
	timeout       *time.Timer
	mutex         sync.Mutex
	totalCpuUsage int

	State               string `json:"state"`
	CpuUsage            int    `json:"cpuUsage"`
	CpuShares           int    `json:"cpuShares"`
	MemoryUsage         int    `json:"memoryUsage"`
	PhysicalMemoryLimit int    `json:"physicalMemoryLimit"`
	TotalMemoryLimit    int    `json:"totalMemoryLimit"`
}

var infos = make(map[bson.ObjectId]*VMInfo)
var infosMutex sync.Mutex
var templateDir = config.Current.ProjectRoot + "/go/templates"
var firstContainerIP net.IP
var containerSubnet *net.IPNet
var shuttingDown = false
var requestWaitGroup sync.WaitGroup

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

	go ldapserver.Listen()
	go LimiterLoop()
	k := kite.New("os", true)

	dirs, err := ioutil.ReadDir("/var/lib/lxc")
	if err != nil {
		log.LogError(err, 0)
		return
	}
	for _, dir := range dirs {
		if strings.HasPrefix(dir.Name(), "vm-") {
			vm := virt.VM{Id: bson.ObjectIdHex(dir.Name()[3:])}
			info := newInfo(&vm)
			infos[vm.Id] = info
			info.startTimeout()
		}
	}

	sigtermChannel := make(chan os.Signal)
	signal.Notify(sigtermChannel, syscall.SIGINT, syscall.SIGTERM, syscall.SIGUSR1)
	go func() {
		sig := <-sigtermChannel
		shuttingDown = true
		requestWaitGroup.Wait()
		if sig == syscall.SIGUSR1 {
			for _, info := range infos {
				info.unprepareVM()
			}
			if _, err := db.VMs.UpdateAll(bson.M{"hostKite": k.ServiceUniqueName}, bson.M{"$set": bson.M{"hostKite": nil}}); err != nil { // ensure that really all are set to nil
				log.LogError(err, 0)
			}
		}
		log.SendLogsAndExit(0)
	}()

	k.LoadBalancer = func(correlationName string, username string, deadService string) string {
		var vm *virt.VM
		if bson.IsObjectIdHex(correlationName) {
			db.VMs.FindId(bson.ObjectIdHex(correlationName)).One(&vm)
		}
		if vm == nil {
			if err := db.VMs.Find(bson.M{"hostnameAlias": correlationName}).One(&vm); err != nil {
				return k.ServiceUniqueName
			}
		}

		if vm.HostKite == "" {
			return k.ServiceUniqueName
		}
		if vm.HostKite == deadService {
			log.Warn("VM is registered as running on dead service.", correlationName, username, deadService)
			return k.ServiceUniqueName
		}
		return vm.HostKite
	}

	registerVmMethod(k, "vm.start", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		if !vos.Permissions.Sudo {
			return nil, &kite.PermissionError{}
		}
		if err := vos.VM.Start(); err != nil {
			panic(err)
		}
		return true, nil
	})

	registerVmMethod(k, "vm.shutdown", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		if !vos.Permissions.Sudo {
			return nil, &kite.PermissionError{}
		}
		if err := vos.VM.Shutdown(); err != nil {
			panic(err)
		}
		return true, nil
	})

	registerVmMethod(k, "vm.stop", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		if !vos.Permissions.Sudo {
			return nil, &kite.PermissionError{}
		}
		if err := vos.VM.Stop(); err != nil {
			panic(err)
		}
		return true, nil
	})

	registerVmMethod(k, "vm.reinitialize", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		if !vos.Permissions.Sudo {
			return nil, &kite.PermissionError{}
		}
		vos.VM.Prepare(true)
		if err := vos.VM.Start(); err != nil {
			panic(err)
		}
		return true, nil
	})

	registerVmMethod(k, "vm.info", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		info := infos[vos.VM.Id]
		info.State = vos.VM.GetState()
		return info, nil
	})

	registerVmMethod(k, "vm.resizeDisk", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		if !vos.Permissions.Sudo {
			return nil, &kite.PermissionError{}
		}
		return true, vos.VM.ResizeRBD()
	})

	// registerVmMethod(k, "vm.createSnapshot", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	// 	if !vos.Permissions.Sudo {
	// 		return nil, &kite.PermissionError{}
	// 	}

	// 	snippet := virt.VM{
	// 		Id:         bson.NewObjectId(),
	// 		SnapshotOf: vos.VM.Id,
	// 	}

	// 	if err := vos.VM.CreateConsistentSnapshot(snippet.Id.Hex()); err != nil {
	// 		return nil, err
	// 	}

	// 	if err := db.VMs.Insert(snippet); err != nil {
	// 		return nil, err
	// 	}

	// 	return snippet.Id.Hex(), nil
	// })

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
	k.Handle(method, concurrent, func(args *dnode.Partial, channel *kite.Channel) (methodReturnValue interface{}, methodError error) {
		if shuttingDown {
			return nil, errors.New("Kite is shutting down.")
		}
		requestWaitGroup.Add(1)
		defer requestWaitGroup.Done()
		if shuttingDown { // check second time after sync to avoid additional mutex
			return nil, errors.New("Kite is shutting down.")
		}

		var user virt.User
		if err := db.Users.Find(bson.M{"username": channel.Username}).One(&user); err != nil {
			panic(err)
		}
		if user.Uid < virt.UserIdOffset {
			panic("User with too low uid.")
		}

		info, _ := channel.KiteData.(*VMInfo)
		var vm *virt.VM

		query := bson.M{"hostnameAlias": channel.CorrelationName}
		if bson.IsObjectIdHex(channel.CorrelationName) {
			query = bson.M{"_id": bson.ObjectIdHex(channel.CorrelationName)}
		}
		if info != nil {
			query = bson.M{"_id": info.vmId}
		}
		if err := db.VMs.Find(query).One(&vm); err != nil {
			return nil, &VMNotFoundError{Name: channel.CorrelationName}
		}

		permissions := vm.GetPermissions(&user)
		if permissions == nil {
			return nil, &kite.PermissionError{}
		}

		if vm.HostKite != k.ServiceUniqueName {
			if err := db.VMs.Update(bson.M{"_id": vm.Id, "hostKite": nil}, bson.M{"$set": bson.M{"hostKite": k.ServiceUniqueName}}); err != nil {
				time.Sleep(time.Second) // to avoid rapid cycle channel loop
				return nil, &kite.WrongChannelError{}
			}
			vm.HostKite = k.ServiceUniqueName
		}

		if info == nil {
			infosMutex.Lock()
			var found bool
			info, found = infos[vm.Id]
			if !found {
				info = newInfo(vm)
				infos[vm.Id] = info
			}
			infosMutex.Unlock()
		}

		info.mutex.Lock()
		defer info.mutex.Unlock()

		if channel.KiteData == nil {
			info.useCounter += 1
			if info.timeout != nil {
				info.timeout.Stop()
				info.timeout = nil
			}

			channel.KiteData = info
			channel.OnDisconnect(func() {
				info.mutex.Lock()
				defer info.mutex.Unlock()

				info.useCounter -= 1
				if info.useCounter == 0 {
					info.startTimeout()
				}
			})
		}

		defer func() {
			if err := recover(); err != nil {
				log.LogError(err, 1, channel.Username, channel.CorrelationName, vm.String())
				methodError = &kite.InternalKiteError{}
			}
		}()

		if vm.IP == nil {
			ipInt := db.NextCounterValue("vm_ip", int(binary.BigEndian.Uint32(firstContainerIP.To4())))
			ip := net.IPv4(byte(ipInt>>24), byte(ipInt>>16), byte(ipInt>>8), byte(ipInt))
			if err := db.VMs.Update(bson.M{"_id": vm.Id, "ip": nil}, bson.M{"$set": bson.M{"ip": ip}}); err != nil {
				panic(err)
			}
			vm.IP = ip
		}
		if !containerSubnet.Contains(vm.IP) {
			panic("VM with IP that is not in the container subnet: " + vm.IP.String())
		}

		if vm.LdapPassword == "" {
			ldapPassword := utils.RandomString()
			if err := db.VMs.Update(bson.M{"_id": vm.Id}, bson.M{"$set": bson.M{"ldapPassword": ldapPassword}}); err != nil {
				panic(err)
			}
			vm.LdapPassword = ldapPassword
		}

		if _, err := os.Stat(vm.File("rootfs/dev")); err != nil {
			if !os.IsNotExist(err) {
				panic(err)
			}
			vm.Prepare(false)
			if err := vm.Start(); err != nil {
				log.LogError(err, 0)
			}
		}

		vmWebDir := "/home/" + vm.WebHome + "/Web"
		userWebDir := "/home/" + user.Name + "/Web"

		rootVos, err := vm.OS(&virt.RootUser)
		if err != nil {
			panic(err)
		}
		userVos, err := vm.OS(&user)
		if err != nil {
			panic(err)
		}
		vmWebVos := rootVos
		if vmWebDir == userWebDir {
			vmWebVos = userVos
		}

		createUserHome(&user, rootVos, userVos)
		createVmWebDir(vm, vmWebDir, rootVos, vmWebVos)
		if vmWebDir != userWebDir {
			createUserWebDir(&user, vmWebDir, userWebDir, rootVos, userVos)
		}

		if concurrent {
			requestWaitGroup.Done()
			defer requestWaitGroup.Add(1)
			info.mutex.Unlock()
			defer info.mutex.Lock()
		}
		return callback(args, channel, userVos)
	})
}

func createUserHome(user *virt.User, rootVos, userVos *virt.VOS) {
	if _, err := rootVos.Stat("/home/" + user.Name); err == nil {
		return
	}
	// home directory does not yes exist

	if _, err := rootVos.Stat("/home/" + user.OldName); user.OldName != "" && err == nil {
		if err := rootVos.Rename("/home/"+user.OldName, "/home/"+user.Name); err != nil {
			panic(err)
		}
		if err := rootVos.Symlink(user.Name, "/home/"+user.OldName); err != nil {
			panic(err)
		}

		if target, err := rootVos.Readlink("/var/www"); err == nil && target == "/home/"+user.OldName+"/Web" {
			if err := rootVos.Remove("/var/www"); err != nil {
				panic(err)
			}
			if err := rootVos.Symlink("/home/"+user.Name+"/Web", "/var/www"); err != nil {
				panic(err)
			}
		}

		ldapserver.ClearCache()
		return
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

func createVmWebDir(vm *virt.VM, vmWebDir string, rootVos, vmWebVos *virt.VOS) {
	if err := rootVos.Symlink(vmWebDir, "/var/www"); err != nil {
		if !os.IsExist(err) {
			panic(err)
		}
		return
	}
	// symlink successfully created

	if _, err := rootVos.Stat(vmWebDir); err == nil {
		return
	}
	// vmWebDir directory does not yes exist

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

func createUserWebDir(user *virt.User, vmWebDir, userWebDir string, rootVos, userVos *virt.VOS) {
	if _, err := rootVos.Stat(userWebDir); err == nil {
		return
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
		vmId:             vm.Id,
		vmName:           vm.String(),
		useCounter:       0,
		totalCpuUsage:    utils.MaxInt,
		CpuShares:        1000,
		TotalMemoryLimit: MaxMemoryLimit,
	}
}

func (info *VMInfo) startTimeout() {
	info.timeout = time.AfterFunc(10*time.Minute, func() {
		if info.useCounter != 0 {
			return
		}
		info.unprepareVM()
	})
}

func (info *VMInfo) unprepareVM() {
	infosMutex.Lock()
	defer infosMutex.Unlock()

	if err := virt.UnprepareVM(info.vmId); err != nil {
		log.Warn(err.Error())
	}

	if err := db.VMs.Update(bson.M{"_id": info.vmId}, bson.M{"$set": bson.M{"hostKite": nil}}); err != nil && err != mgo.ErrNotFound {
		log.LogError(err, 0)
	}

	delete(infos, info.vmId)
}
