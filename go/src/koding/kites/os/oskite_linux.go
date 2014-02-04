package main

import (
	"encoding/binary"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	kitelib "koding/kite"
	"koding/kites/os/ldapserver"
	"koding/kodingkite"
	"koding/tools/config"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/tools/lifecycle"
	"koding/tools/logger"
	"koding/tools/utils"
	"koding/virt"
	"net"
	"os"
	"os/signal"
	"strings"
	"sync"
	"syscall"
	"time"
	"github.com/op/go-logging"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

var log = logger.New("oskite")

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

var (
	infos            = make(map[bson.ObjectId]*VMInfo)
	infosMutex       sync.Mutex
	templateDir      = "files/templates" // should be in the same dir as the binary
	firstContainerIP net.IP
	containerSubnet  *net.IPNet
	shuttingDown     = false
	requestWaitGroup sync.WaitGroup

	prepareQueueLimit = 8 + 1 // number of concurrent VM preparations, shoulde be CPU + 1
	prepareQueue      = make(chan func(chan struct{}))
)

func main() {
	initializeSettings()

	k := prepareOsKite()

	runNewKite(k.ServiceUniqueName)

	// handle leftover VMs
	handleCurrentVMS(k)

	// start pinned always-on VMs
	startPinnedVMS(k)

	// handle SIGUSR1 and other signals. Shutdown gracely when USR1 is received
	setupSignalHandler(k)

	// register current client-side methods
	registerVmMethods(k)
	registerS3Methods(k)
	registerFileSystemMethods(k)
	registerWebtermMethods(k)
	registerAppMethods(k)

	startPrepareWorkers()

	k.Run()
}

func runNewKite(serviceUniqueName string) {
	k := kodingkite.New(kodingkite.Options{
		Kitename: "oskite",
		Version:  "0.0.1",
		Port:     "5000",
	})

	k.HandleFunc("startVM", func(r *kitelib.Request) (interface{}, error) {
		hostnameAlias := r.Args.One().MustString()
		// just print hostnameAlias for now
		fmt.Println("got request from", r.RemoteKite.Name, "starting:", hostnameAlias)

		v, err := modelhelper.GetVM(hostnameAlias)
		if err != nil {
			return nil, err
		}

		vm := virt.VM(*v)
		vm.ApplyDefaults()

		err = validateVM(&vm, serviceUniqueName)
		if err != nil {
			return nil, err
		}

		isPrepared := true
		if _, err := os.Stat(vm.File("rootfs/dev")); err != nil {
			if !os.IsNotExist(err) {
				panic(err)
			}
			isPrepared = false
		}

		if !isPrepared {
			fmt.Println("preparing ", hostnameAlias)
			vm.Prepare(false, log.Warning)
		}

		fmt.Println("starting ", hostnameAlias)
		if err := vm.Start(); err != nil {
			log.LogError(err, 0)
		}

		// wait until network is up
		if err := vm.WaitForNetwork(time.Second * 5); err != nil {
			log.LogError(err, 0)
		}

		// return back the IP address of the started vm
		return vm.IP.String(), nil
	})

	k.Start()

	// TODO: remove this later, this is needed in order to reinitiliaze the logger package
	logging.SetLevel(logging.INFO, "oskite")
}

func initializeSettings() {
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
}

func prepareOsKite() *kite.Kite {
	kiteName := "os"
	if config.Region != "" {
		kiteName += "-" + config.Region
	}

	k := kite.New(kiteName, true)

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

		// Set hostkite to nil if we detect a dead service. On the next call,
		// Oskite will point to an health service in validateVM function()
		// because it will detect that the hostkite is nil and change it to
		// the healthy service given by the client.
		if vm.HostKite == deadService {
			log.Warning("VM is registered as running on dead service. %v, %v, %v",
				correlationName, username, deadService)

			query := func(c *mgo.Collection) error {
				return c.Update(bson.M{"_id": vm.Id}, bson.M{"$set": bson.M{"hostKite": nil}})
			}

			if err := mongodb.Run("jVMs", query); err != nil {
				log.LogError(err, 0, vm.Id.Hex())
			}

			return k.ServiceUniqueName
		}

		return vm.HostKite
	}

	return k
}

// handleCurrentVMS removes and unprepare any vm in the lxc dir that doesn't
// have any associated document which in mongodb.
func handleCurrentVMS(k *kite.Kite) {
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
				log.Info("oskite started. I'm calling unprepare for leftover VM: '%s', vm.Hoskite: '%s', k.ServiceUniqueName: '%s', error '%s'", vmId, vm.HostKite, k.ServiceUniqueName, err)

				if err := virt.UnprepareVM(vmId); err != nil {
					log.Error("%v", err)
				}
				continue
			}

			vm.ApplyDefaults()
			info := newInfo(&vm)
			infos[vm.Id] = info
			info.startTimeout()
		}
	}
}

func startPinnedVMS(k *kite.Kite) {
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

}

func setupSignalHandler(k *kite.Kite) {
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

		log.Fatal()
	}()
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

		user, err := getUser(channel.Username)
		if err != nil {
			return nil, err
		}

		vm, err := getVM(channel)
		if err != nil {
			return nil, err
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
					return nil, &kite.BaseError{
						Message: "Invalid session identifier",
						CodeErr: ErrInvalidSession,
					}
				}

				if vm.GetState() != "RUNNING" {
					return nil, errors.New("VM not running.")
				}

				if err := mongodb.Run("jUsers", func(c *mgo.Collection) error {
					return c.Find(bson.M{"username": params.JoinUser}).One(&user)
				}); err != nil {
					panic(err)
				}

				return callback(args, channel, &virt.VOS{VM: vm, User: user})
			}
		}

		permissions := vm.GetPermissions(user)
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

		userVos, err := vm.OS(user)
		if err != nil {
			panic(err)
		}
		vmWebVos := rootVos
		if vmWebDir == userWebDir {
			vmWebVos = userVos
		}

		rootVos.Chmod("/", 0755)     // make sure that executable flag is set
		rootVos.Chmod("/home", 0755) // make sure that executable flag is set
		createUserHome(user, rootVos, userVos)
		createVmWebDir(vm, vmWebDir, rootVos, vmWebVos)
		if vmWebDir != userWebDir {
			createUserWebDir(user, vmWebDir, userWebDir, rootVos, userVos)
		}

		if concurrent {
			requestWaitGroup.Done()
			defer requestWaitGroup.Add(1)
		}
		return callback(args, channel, userVos)
	})
}

func getUser(username string) (*virt.User, error) {
	var user *virt.User
	if err := mongodb.Run("jUsers", func(c *mgo.Collection) error {
		return c.Find(bson.M{"username": username}).One(&user)
	}); err != nil {
		if err != mgo.ErrNotFound {
			panic(err)
		}

		if !strings.HasPrefix(username, "guest-") {
			log.Warning("User not found: %v", username)
		}

		time.Sleep(time.Second) // to avoid rapid cycle channel loop
		return nil, &kite.WrongChannelError{}
	}

	if user.Uid < virt.UserIdOffset {
		panic("User with too low uid.")
	}

	return user, nil
}

func getVM(channel *kite.Channel) (*virt.VM, error) {
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

	return vm, nil
}

func validateVM(vm *virt.VM, serviceUniqueName string) error {
	if vm.Region != config.Region {
		time.Sleep(time.Second) // to avoid rapid cycle channel loop
		return &kite.WrongChannelError{}
	}

	if vm.HostKite == "(maintenance)" {
		return &UnderMaintenanceError{}
	}

	if vm.HostKite == "(banned)" {
		log.Warning("vm '%s' is banned", vm.HostnameAlias)
		return &AccessDeniedError{}
	}

	if vm.IP == nil {
		ipInt := NextCounterValue("vm_ip", int(binary.BigEndian.Uint32(firstContainerIP.To4())))
		ip := net.IPv4(byte(ipInt>>24), byte(ipInt>>16), byte(ipInt>>8), byte(ipInt))

		updateErr := mongodb.Run("jVMs", func(c *mgo.Collection) error {
			return c.Update(bson.M{"_id": vm.Id, "ip": nil}, bson.M{"$set": bson.M{"ip": ip}})
		})

		if updateErr != nil {
			var logVM *virt.VM
			err := mongodb.One("jVMs", vm.Id.Hex(), &logVM)
			if err != nil {
				errLog := fmt.Sprintf("Vm %s does not exist for updating IP. This is a race condition", vm.Id.Hex())
				log.LogError(errLog, 0)
			} else {
				errLog := fmt.Sprintf("Vm %s does exist for updating IP but it tries to replace it. This is a race condition", vm.Id.Hex())
				log.LogError(errLog, 0, logVM)
			}

			panic(updateErr)
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

	if vm.HostKite != serviceUniqueName {
		err := mongodb.Run("jVMs", func(c *mgo.Collection) error {
			return c.Update(bson.M{"_id": vm.Id, "hostKite": nil}, bson.M{"$set": bson.M{"hostKite": serviceUniqueName}})
		})
		if err != nil {
			time.Sleep(time.Second) // to avoid rapid cycle channel loop
			return &kite.WrongChannelError{}
		}

		vm.HostKite = serviceUniqueName
	}

	return nil
}

func startVM(k *kite.Kite, vm *virt.VM, channel *kite.Channel) error {
	err := validateVM(vm, k.ServiceUniqueName)
	if err != nil {
		return err
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

	isPrepared := true
	if _, err := os.Stat(vm.File("rootfs/dev")); err != nil {
		if !os.IsNotExist(err) {
			panic(err)
		}
		isPrepared = false
	}

	if !isPrepared || info.currentHostname != vm.HostnameAlias {
		log.Info("putting %s into queue. total vms in queue: %d of %d",
			vm.HostnameAlias, len(prepareQueue), prepareQueueLimit)

		wait := make(chan struct{}, 0)
		prepareQueue <- func(done chan struct{}) {
			defer func() {
				done <- struct{}{}
				wait <- struct{}{}
			}()

			startTime := time.Now()
			vm.Prepare(false, log.Warning)
			if err := vm.Start(); err != nil {
				log.LogError(err, 0)
			}

			// wait until network is up
			if err := vm.WaitForNetwork(time.Second * 5); err != nil {
				log.Error("%v", err)
			}

			endTime := time.Now()
			log.Info("VM PREPARE and START: %s [%s] - ElapsedTime: %.10f seconds.",
				vm, vm.HostnameAlias, endTime.Sub(startTime).Seconds())

			info.currentHostname = vm.HostnameAlias
		}

		// wait until the prepareWorker has picked us and we finished
		<-wait
	}

	return nil
}

// prepareWorker listens from prepareQueue channel and runs the functions it receives
func prepareWorker() {
	for fn := range prepareQueue {
		done := make(chan struct{}, 1)
		go fn(done)

		select {
		case <-done:
			log.Info("done preparing vm")
		case <-time.After(time.Second * 20):
			log.Error("timing out preparing vm")
		}
	}
}

// startPrepareWorkers starts multiple workers (based on prepareQueueLimit)
// that accepts prepare functions.
func startPrepareWorkers() {
	for i := 0; i < prepareQueueLimit; i++ {
		go prepareWorker()
	}
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

	// After 1 hour we are shutting down the VM (unprepareVM does it.)
	// 5 Minutes from kite.go, 50 + 5 Minutes from here, makes a total of 60 Mins (1 Hour)
	info.timeout = time.AfterFunc(50*time.Minute, func() {
		if info.useCounter != 0 || info.vm.AlwaysOn {
			return
		}
		if info.vm.GetState() == "RUNNING" {
			if err := info.vm.SendMessageToVMUsers("========================================\nThis VM will be turned off in 5 minutes.\nLog in to Koding.com to keep it running.\n========================================\n"); err != nil {
				log.Warning("%v", err)
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
		log.Warning("%v", err)
	}

	if err := mongodb.Run("jVMs", func(c *mgo.Collection) error {
		return c.Update(bson.M{"_id": info.vm.Id}, bson.M{"$set": bson.M{"hostKite": nil}})
	}); err != nil {
		log.LogError(err, 0, info.vm.Id.Hex())
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

type UnderMaintenanceError struct{}

func (err *UnderMaintenanceError) Error() string {
	return "VM is under maintenance."
}

type AccessDeniedError struct{}

func (err *AccessDeniedError) Error() string {
	return "Vm is banned"
}

type VMNotFoundError struct {
	Name string
}

func (err *VMNotFoundError) Error() string {
	return "There is no VM with hostname/id '" + err.Name + "'."
}
