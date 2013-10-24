package main

import (
	"encoding/binary"
	"errors"
	"io"
	"io/ioutil"
	"koding/db/mongodb"
	"koding/kites/os/ldapserver"
	"koding/tools/config"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/tools/lifecycle"
	"koding/tools/log"
	"koding/tools/utils"
	"koding/virt"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"launchpad.net/goamz/aws"
	"launchpad.net/goamz/s3"
	"net"
	"os"
	"os/signal"
	"strings"
	"sync"
	"syscall"
	"time"
)

type VMInfo struct {
	vm              *virt.VM
	useCounter      int
	timeout         *time.Timer
	mutex           sync.Mutex
	totalCpuUsage   int
	currentCpus     []string
	currentHostname string

	State               string `json:"state"`
	CpuUsage            int    `json:"cpuUsage"`
	CpuShares           int    `json:"cpuShares"`
	MemoryUsage         int    `json:"memoryUsage"`
	PhysicalMemoryLimit int    `json:"physicalMemoryLimit"`
	TotalMemoryLimit    int    `json:"totalMemoryLimit"`
}

type UnderMaintenanceError struct{}

func (err *UnderMaintenanceError) Error() string {
	return "VM is under maintenance."
}

type AccessDeniedError struct{}

func (err *AccessDeniedError) Error() string {
	return "Vm is banned"
}

var infos = make(map[bson.ObjectId]*VMInfo)
var infosMutex sync.Mutex
var templateDir = config.Current.ProjectRoot + "/go/templates"
var firstContainerIP net.IP
var containerSubnet *net.IPNet
var shuttingDown = false
var requestWaitGroup sync.WaitGroup

var s3store = s3.New(
	aws.Auth{
		AccessKey: "AKIAJI6CLCXQ73BBQ2SQ",
		SecretKey: "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",
	},
	aws.USEast,
)
var uploadsBucket = s3store.Bucket("koding-uploads")
var appsBucket = s3store.Bucket("koding-apps")

func main() {
	lifecycle.Startup("kite.os", true)

	var err error
	if firstContainerIP, containerSubnet, err = net.ParseCIDR(config.Current.ContainerSubnet); err != nil {
		log.LogError(err, 0)
		return
	}

	virt.VMPool = config.Current.VmPool
	if err := virt.LoadTemplates(templateDir); err != nil {
		log.LogError(err, 0)
		return
	}

	go ldapserver.Listen()
	go LimiterLoop()
	kiteName := "os"
	if config.Region != "" {
		kiteName += "-" + config.Region
	}
	k := kite.New(kiteName, true)

	// handle leftover VMs
	dirs, err := ioutil.ReadDir("/var/lib/lxc")
	if err != nil {
		log.LogError(err, 0)
		return
	}
	for _, dir := range dirs {
		if strings.HasPrefix(dir.Name(), "vm-") {
			vmId := bson.ObjectIdHex(dir.Name()[3:])
			var vm virt.VM
			query := func(c *mgo.Collection) error {
				return c.FindId(vmId).One(&vm)
			}

			if err := mongodb.Run("jVMs", query); err != nil || vm.HostKite != k.ServiceUniqueName {
				if err := virt.UnprepareVM(vmId); err != nil {
					log.Warn(err.Error())
				}
				continue
			}
			vm.ApplyDefaults()
			info := newInfo(&vm)
			infos[vm.Id] = info
			info.startTimeout()
		}
	}

	// start pinned always-on VMs
	mongodb.Run("jVMs", func(c *mgo.Collection) error {
		iter := c.Find(bson.M{"pinnedToHost": k.ServiceUniqueName, "alwaysOn": true}).Iter()
		for {
			var vm virt.VM
			if !iter.Next(&vm) {
				break
			}
			if err := startVM(k, &vm, nil); err != nil {
				log.LogError(err, 0)
			}
		}
		if err := iter.Close(); err != nil {
			panic(err)
		}
		return nil
	})

	sigtermChannel := make(chan os.Signal)
	signal.Notify(sigtermChannel, syscall.SIGINT, syscall.SIGTERM, syscall.SIGUSR1)
	go func() {
		sig := <-sigtermChannel
		log.Info("Shutdown initiated.")
		shuttingDown = true
		requestWaitGroup.Wait()
		if sig == syscall.SIGUSR1 {
			for _, info := range infos {
				log.Info("Unpreparing " + info.vm.String() + "...")
				info.unprepareVM()
			}
			query := func(c *mgo.Collection) error {
				_, err := c.UpdateAll(
					bson.M{"hostKite": k.ServiceUniqueName},
					bson.M{"$set": bson.M{"hostKite": nil}},
				) // ensure that really all are set to nil
				return err
			}

			err := mongodb.Run("jVMs", query)
			if err != nil {
				log.LogError(err, 0)
			}
		}
		log.SendLogsAndExit(0)
	}()

	k.LoadBalancer = func(correlationName string, username string, deadService string) string {
		var vm *virt.VM
		if bson.IsObjectIdHex(correlationName) {
			mongodb.Run("jVMs", func(c *mgo.Collection) error {
				return c.FindId(bson.ObjectIdHex(correlationName)).One(&vm)
			})
		}
		if vm == nil {
			if err := mongodb.Run("jVMs", func(c *mgo.Collection) error {
				return c.Find(bson.M{"hostnameAlias": correlationName}).One(&vm)
			}); err != nil {
				return k.ServiceUniqueName
			}
		}

		if vm.HostKite == "" || vm.HostKite == "(maintenance)" || vm.HostKite == "(banned)" {
			if vm.PinnedToHost != "" {
				return vm.PinnedToHost
			}
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
		vos.VM.Prepare(true, log.Warn)
		if err := vos.VM.Start(); err != nil {
			panic(err)
		}
		return true, nil
	})

	registerVmMethod(k, "vm.info", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		info := channel.KiteData.(*VMInfo)
		info.State = vos.VM.GetState()
		return info, nil
	})

	registerVmMethod(k, "vm.resizeDisk", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		if !vos.Permissions.Sudo {
			return nil, &kite.PermissionError{}
		}
		return true, vos.VM.ResizeRBD()
	})

	registerVmMethod(k, "vm.createSnapshot", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		if !vos.Permissions.Sudo {
			return nil, &kite.PermissionError{}
		}

		snippetId := bson.NewObjectId().Hex()
		if err := vos.VM.CreateConsistentSnapshot(snippetId); err != nil {
			return nil, err
		}

		return snippetId, nil
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

	registerVmMethod(k, "s3.store", true, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		var params struct {
			Name    string
			Content []byte
		}
		if args.Unmarshal(&params) != nil || params.Name == "" || len(params.Content) == 0 || strings.Contains(params.Name, "/") {
			return nil, &kite.ArgumentError{Expected: "{ name: [string], content: [base64 string] }"}
		}

		if len(params.Content) > 2*1024*1024 {
			return nil, errors.New("Content size larger than maximum of 2MB.")
		}

		result, err := uploadsBucket.List(UserAccountId(vos.User).Hex()+"/", "", "", 100)
		if err != nil {
			return nil, err
		}
		if len(result.Contents) >= 100 {
			return nil, errors.New("Maximum of 100 stored files reached.")
		}

		if err := uploadsBucket.Put(UserAccountId(vos.User).Hex()+"/"+params.Name, params.Content, "", s3.Private); err != nil {
			return nil, err
		}
		return true, nil
	})

	registerVmMethod(k, "s3.delete", true, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		var params struct {
			Name string
		}
		if args.Unmarshal(&params) != nil || params.Name == "" || strings.Contains(params.Name, "/") {
			return nil, &kite.ArgumentError{Expected: "{ name: [string] }"}
		}
		if err := uploadsBucket.Del(UserAccountId(vos.User).Hex() + "/" + params.Name); err != nil {
			return nil, err
		}
		return true, nil
	})

	registerFileSystemMethods(k)
	registerWebtermMethods(k)
	registerAppMethods(k)

	k.Run()
}

func UserAccountId(user *virt.User) bson.ObjectId {
	var account struct {
		Id bson.ObjectId `bson:"_id"`
	}
	if err := mongodb.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": user.Name}).One(&account)
	}); err != nil {
		panic(err)
	}
	return account.Id
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
		if err := mongodb.Run("jUsers", func(c *mgo.Collection) error {
			return c.Find(bson.M{"username": channel.Username}).One(&user)
		}); err != nil {
			if err != mgo.ErrNotFound {
				panic(err)
			}
			if !strings.HasPrefix(channel.Username, "guest-") {
				log.Warn("User not found.", channel.Username)
			}
			time.Sleep(time.Second) // to avoid rapid cycle channel loop
			return nil, &kite.WrongChannelError{}
		}
		if user.Uid < virt.UserIdOffset {
			panic("User with too low uid.")
		}

		var vm *virt.VM
		query := bson.M{"hostnameAlias": channel.CorrelationName}
		if bson.IsObjectIdHex(channel.CorrelationName) {
			query = bson.M{"_id": bson.ObjectIdHex(channel.CorrelationName)}
		}
		if info, _ := channel.KiteData.(*VMInfo); info != nil {
			query = bson.M{"_id": info.vm.Id}
		}
		if err := mongodb.Run("jVMs", func(c *mgo.Collection) error {
			return c.Find(query).One(&vm)
		}); err != nil {
			return nil, &VMNotFoundError{Name: channel.CorrelationName}
		}
		vm.ApplyDefaults()

		defer func() {
			if err := recover(); err != nil {
				log.LogError(err, 1, channel.Username, channel.CorrelationName, vm.String())
				time.Sleep(time.Second) // penalty for avoiding that the client rapidly sends the request again on error
				methodError = &kite.InternalKiteError{}
			}
		}()

		if method == "webterm.connect" {
			var params struct {
				JoinUser string
				Session  string
			}
			args.Unmarshal(&params)
			if params.JoinUser != "" {
				if len(params.Session) != utils.RandomStringLength {
					return nil, errors.New("Invalid session identifier.")
				}
				if vm.GetState() != "RUNNING" {
					return nil, errors.New("VM not running.")
				}
				if err := mongodb.Run("jUsers", func(c *mgo.Collection) error {
					return c.Find(bson.M{"username": params.JoinUser}).One(&user)
				}); err != nil {
					panic(err)
				}
				if user.Uid < virt.UserIdOffset {
					panic("User with too low uid.")
				}
				return callback(args, channel, &virt.VOS{VM: vm, User: &user})
			}
		}

		permissions := vm.GetPermissions(&user)
		if permissions == nil {
			return nil, &kite.PermissionError{}
		}

		if err := startVM(k, vm, channel); err != nil {
			return nil, err
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

		rootVos.Chmod("/", 0755)     // make sure that executable flag is set
		rootVos.Chmod("/home", 0755) // make sure that executable flag is set
		createUserHome(&user, rootVos, userVos)
		createVmWebDir(vm, vmWebDir, rootVos, vmWebVos)
		if vmWebDir != userWebDir {
			createUserWebDir(&user, vmWebDir, userWebDir, rootVos, userVos)
		}

		if concurrent {
			requestWaitGroup.Done()
			defer requestWaitGroup.Add(1)
		}
		return callback(args, channel, userVos)
	})
}

func startVM(k *kite.Kite, vm *virt.VM, channel *kite.Channel) error {
	if vm.Region != config.Region {
		time.Sleep(time.Second) // to avoid rapid cycle channel loop
		return &kite.WrongChannelError{}
	}

	if vm.HostKite == "(maintenance)" {
		return &UnderMaintenanceError{}
	}

	if vm.HostKite == "(banned)" {
		log.Warn("vm '%s' is banned", vm.HostnameAlias)
		return &AccessDeniedError{}
	}

	if vm.HostKite != k.ServiceUniqueName {
		if err := mongodb.Run("jVMs", func(c *mgo.Collection) error {
			return c.Update(bson.M{"_id": vm.Id, "hostKite": nil}, bson.M{"$set": bson.M{"hostKite": k.ServiceUniqueName}})
		}); err != nil {
			time.Sleep(time.Second) // to avoid rapid cycle channel loop
			return &kite.WrongChannelError{}
		}
		vm.HostKite = k.ServiceUniqueName
	}

	var info *VMInfo
	if channel != nil {
		info, _ = channel.KiteData.(*VMInfo)
	}
	if info == nil {
		infosMutex.Lock()
		var found bool
		info, found = infos[vm.Id]
		if !found {
			info = newInfo(vm)
			infos[vm.Id] = info
		}

		if channel != nil {
			info.useCounter += 1
			info.timeout.Stop()

			channel.KiteData = info
			channel.OnDisconnect(func() {
				info.mutex.Lock()
				defer info.mutex.Unlock()

				info.useCounter -= 1
				info.startTimeout()
			})
		}

		infosMutex.Unlock()
	}

	info.vm = vm
	info.mutex.Lock()
	defer info.mutex.Unlock()

	if vm.IP == nil {
		ipInt := NextCounterValue("vm_ip", int(binary.BigEndian.Uint32(firstContainerIP.To4())))
		ip := net.IPv4(byte(ipInt>>24), byte(ipInt>>16), byte(ipInt>>8), byte(ipInt))
		if err := mongodb.Run("jVMs", func(c *mgo.Collection) error {
			return c.Update(bson.M{"_id": vm.Id, "ip": nil}, bson.M{"$set": bson.M{"ip": ip}})
		}); err != nil {
			panic(err)
		}
		vm.IP = ip
	}
	if !containerSubnet.Contains(vm.IP) {
		panic("VM with IP that is not in the container subnet: " + vm.IP.String())
	}

	if vm.LdapPassword == "" {
		ldapPassword := utils.RandomString()
		if err := mongodb.Run("jVMs", func(c *mgo.Collection) error {
			return c.Update(bson.M{"_id": vm.Id}, bson.M{"$set": bson.M{"ldapPassword": ldapPassword}})
		}); err != nil {
			panic(err)
		}
		vm.LdapPassword = ldapPassword
	}

	isPrepared := true
	if _, err := os.Stat(vm.File("rootfs/dev")); err != nil {
		if !os.IsNotExist(err) {
			panic(err)
		}
		isPrepared = false
	}
	if !isPrepared || info.currentHostname != vm.HostnameAlias {
		vm.Prepare(false, log.Warn)
		if err := vm.Start(); err != nil {
			log.LogError(err, 0)
		}
		info.currentHostname = vm.HostnameAlias
	}

	return nil
}

func createUserHome(user *virt.User, rootVos, userVos *virt.VOS) {
	if info, err := rootVos.Stat("/home/" + user.Name); err == nil {
		rootVos.Chmod("/home/"+user.Name, info.Mode().Perm()|0511) // make sure that user read and executable flag is set
		return
	}
	// home directory does not yet exist

	if _, err := rootVos.Stat("/home/" + user.OldName); user.OldName != "" && err == nil {
		if err := rootVos.Rename("/home/"+user.OldName, "/home/"+user.Name); err != nil {
			panic(err)
		}
		if err := rootVos.Symlink(user.Name, "/home/"+user.OldName); err != nil {
			panic(err)
		}
		if err := rootVos.Chown("/home/"+user.OldName, user.Uid, user.Uid); err != nil {
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
	// vmWebDir directory does not yet exist

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
	// userWebDir directory does not yet exist

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
		if err := mongodb.Run("jUsers", func(c *mgo.Collection) error {
			return c.FindId(entry.Id).One(&users[i])
		}); err != nil {
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
		vm:                  vm,
		useCounter:          0,
		timeout:             time.NewTimer(0),
		totalCpuUsage:       utils.MaxInt,
		currentCpus:         nil,
		currentHostname:     vm.HostnameAlias,
		CpuShares:           1000,
		PhysicalMemoryLimit: 100 * 1024 * 1024,
		TotalMemoryLimit:    1024 * 1024 * 1024,
	}
}

func (info *VMInfo) startTimeout() {
	if info.useCounter != 0 || info.vm.AlwaysOn {
		return
	}
	info.timeout = time.AfterFunc(5*time.Minute, func() {
		if info.useCounter != 0 || info.vm.AlwaysOn {
			return
		}
		if info.vm.GetState() == "RUNNING" {
			if err := info.vm.SendMessageToVMUsers("========================================\nThis VM will be turned off in 5 minutes.\nLog in to Koding.com to keep it running.\n========================================\n"); err != nil {
				log.Warn(err.Error())
			}
		}
		info.timeout = time.AfterFunc(5*time.Minute, func() {
			info.mutex.Lock()
			defer info.mutex.Unlock()
			if info.useCounter != 0 || info.vm.AlwaysOn {
				return
			}
			info.unprepareVM()
		})
	})
}

func (info *VMInfo) unprepareVM() {
	if err := virt.UnprepareVM(info.vm.Id); err != nil {
		log.Warn(err.Error())
	}

	if err := mongodb.Run("jVMs", func(c *mgo.Collection) error {
		return c.Update(bson.M{"_id": info.vm.Id}, bson.M{"$set": bson.M{"hostKite": nil}})
	}); err != nil {
		log.LogError(err, 0)
	}

	infosMutex.Lock()
	if info.useCounter == 0 {
		delete(infos, info.vm.Id)
	}
	infosMutex.Unlock()
}

type Counter struct {
	Name  string `bson:"_id"`
	Value int    `bson:"seq"`
}

func NextCounterValue(counterName string, initialValue int) int {
	var counter Counter

	if err := mongodb.Run("counters", func(c *mgo.Collection) error {
		_, err := c.FindId(counterName).Apply(mgo.Change{Update: bson.M{"$inc": bson.M{"seq": 1}}}, &counter)
		return err
	}); err != nil {
		if err == mgo.ErrNotFound {
			mongodb.Run("counters", func(c *mgo.Collection) error {
				c.Insert(Counter{Name: counterName, Value: initialValue})
				return nil // ignore error and try to do atomic update again
			})

			if err := mongodb.Run("counters", func(c *mgo.Collection) error {
				_, err := c.FindId(counterName).Apply(mgo.Change{Update: bson.M{"$inc": bson.M{"seq": 1}}}, &counter)
				return err
			}); err != nil {
				panic(err)
			}
			return counter.Value
		}
		panic(err)
	}

	return counter.Value

}
