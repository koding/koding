package main

import (
	"encoding/binary"
	"errors"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	kitelib "kite"
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
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

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

const OSKITE_NAME = "oskite"

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
	log         = logger.New(OSKITE_NAME)
	logLevel    logger.Level
	mongodbConn *mongodb.MongoDB
	conf        *config.Config

	flagProfile   = flag.String("c", "", "Configuration profile from file")
	flagRegion    = flag.String("r", "", "Configuration region from file")
	flagDebug     = flag.Bool("d", false, "Debug mode")
	flagTemplates = flag.String("t", "", "Change template directory")

	infos            = make(map[bson.ObjectId]*VMInfo)
	infosMutex       sync.Mutex
	templateDir      = "files/templates" // should be in the same dir as the binary
	firstContainerIP net.IP
	containerSubnet  *net.IPNet
	shuttingDown     = false
	requestWaitGroup sync.WaitGroup

	// kite unique name of this main process, will be set with kite.ServiceUniqueName
	serviceUniqueName string

	prepareQueueLimit = 8 + 1 // number of concurrent VM preparations, shoulde be CPU + 1
	prepareQueue      = make(chan func(chan struct{}))
)

func main() {
	flag.Parse()
	if *flagProfile == "" || *flagRegion == "" {
		log.Fatal("Please specify profile via -c and region via -r. Aborting.")
	}

	fmt.Println("flags", *flagProfile)
	conf = config.MustConfig(*flagProfile)
	mongodbConn = mongodb.NewMongoDB(conf.Mongo)
	modelhelper.Initialize(conf.Mongo)

	if *flagDebug {
		logLevel = logger.DEBUG
	} else {
		logLevel = logger.GetLoggingLevelFromConfig(OSKITE_NAME, *flagProfile)
	}
	log.SetLevel(logLevel)

	if *flagTemplates != "" {
		templateDir = *flagTemplates
	}

	initializeSettings()

	k := prepareOsKite()
	if k.ServiceUniqueName == "" {
		log.Fatal("service unique name is empty!!!!")
	}
	serviceUniqueName = k.ServiceUniqueName

	runNewKite()

	handleCurrentVMS() // handle leftover VMs
	startPinnedVMS()   // start pinned always-on VMs

	// handle SIGUSR1 and other signals. Shutdown gracely when USR1 is received
	setupSignalHandler()

	// startPrepareWorkers starts multiple workers (based on prepareQueueLimit)
	// that accepts vmPrepare/vmStart functions.
	for i := 0; i < prepareQueueLimit; i++ {
		go prepareWorker()
	}

	// register current client-side methods
	registerMethod(k, "vm.start", false, vmStartOld)
	registerMethod(k, "vm.shutdown", false, vmShutdownOld)
	registerMethod(k, "vm.prepare", false, vmPrepareOld)
	registerMethod(k, "vm.unprepare", false, vmUnprepareOld)
	registerMethod(k, "vm.stop", false, vmStopOld)
	registerMethod(k, "vm.reinitialize", false, vmReinitializeOld)
	registerMethod(k, "vm.info", false, vmInfoOld)
	registerMethod(k, "vm.resizeDisk", false, vmResizeDiskOld)
	registerMethod(k, "vm.createSnapshot", false, vmCreateSnapshotOld)
	registerMethod(k, "spawn", true, spawnOld)
	registerMethod(k, "exec", true, execOld)

	syscall.Umask(0) // don't know why richard calls this
	registerMethod(k, "fs.readDirectory", false, fsReadDirectoryOld)
	registerMethod(k, "fs.glob", false, fsGlobOld)
	registerMethod(k, "fs.readFile", false, fsReadFileOld)
	registerMethod(k, "fs.writeFile", false, fsWriteFileOld)
	registerMethod(k, "fs.ensureNonexistentPath", false, fsEnsureNonexistentPathOld)
	registerMethod(k, "fs.getInfo", false, fsGetInfoOld)
	registerMethod(k, "fs.setPermissions", false, fsSetPermissionsOld)
	registerMethod(k, "fs.remove", false, fsRemoveOld)
	registerMethod(k, "fs.rename", false, fsRenameOld)
	registerMethod(k, "fs.createDirectory", false, fsCreateDirectoryOld)

	registerMethod(k, "app.install", false, appInstallOld)
	registerMethod(k, "app.download", false, appDownloadOld)
	registerMethod(k, "app.publish", false, appPublishOld)
	registerMethod(k, "app.skeleton", false, appSkeletonOld)

	registerMethod(k, "webterm.connect", false, webtermConnect)
	registerMethod(k, "webterm.getSessions", false, webtermGetSessions)

	registerMethod(k, "s3.store", true, s3StoreOld)
	registerMethod(k, "s3.delete", true, s3DeleteOld)

	k.Run()
}

func runNewKite() {
	k := kodingkite.New(
		conf,
		kitelib.Options{
			Kitename: OSKITE_NAME,
			Version:  "0.0.1",
			Port:     "5000",
			Region:   *flagRegion,
		},
	)

	vosMethod(k, "vm.start", vmStartNew)
	vosMethod(k, "vm.shutdown", vmShutdownNew)
	vosMethod(k, "vm.prepare", vmPrepareNew)
	vosMethod(k, "vm.unprepare", vmUnprepareNew)
	vosMethod(k, "vm.stop", vmStopNew)
	vosMethod(k, "vm.reinitialize", vmReinitializeNew)
	vosMethod(k, "vm.info", vmInfoNew)
	vosMethod(k, "vm.resizeDisk", vmResizeDiskNew)
	vosMethod(k, "vm.createSnapshot", vmCreateSnapshotNew)
	vosMethod(k, "spawn", spawnNew)
	vosMethod(k, "exec", execNew)

	vosMethod(k, "fs.readDirectory", fsReadDirectoryNew)
	vosMethod(k, "fs.glob", fsGlobNew)
	vosMethod(k, "fs.readFile", fsReadFileNew)
	vosMethod(k, "fs.writeFile", fsWriteFileNew)
	vosMethod(k, "fs.ensureNonexistentPath", fsEnsureNonexistentPathNew)
	vosMethod(k, "fs.getInfo", fsGetInfoNew)
	vosMethod(k, "fs.setPermissions", fsSetPermissionsNew)
	vosMethod(k, "fs.remove", fsRemoveNew)
	vosMethod(k, "fs.rename", fsRenameNew)
	vosMethod(k, "fs.createDirectory", fsCreateDirectoryNew)

	vosMethod(k, "app.install", appInstallNew)
	vosMethod(k, "app.download", appDownloadNew)
	vosMethod(k, "app.publish", appPublishNew)
	vosMethod(k, "app.skeleton", appSkeletonNew)

	vosMethod(k, "webterm.connect", webtermConnectNew)
	vosMethod(k, "webterm.getSessions", webtermGetSessionsNew)

	vosMethod(k, "s3.store", s3StoreNew)
	vosMethod(k, "s3.delete", s3DeleteNew)

	k.DisableConcurrency() // needed for webterm.connect
	k.Start()

	// TODO: remove this later, this is needed in order to reinitiliaze the logger package
	log.SetLevel(logLevel)
}

func initializeSettings() {
	lifecycle.Startup("kite.os", true)

	var err error
	if firstContainerIP, containerSubnet, err = net.ParseCIDR(conf.ContainerSubnet); err != nil {
		log.LogError(err, 0)
		return
	}

	virt.VMPool = conf.VmPool
	if err := virt.LoadTemplates(templateDir); err != nil {
		log.LogError(err, 0)
		return
	}

	go ldapserver.Listen(conf.Mongo)
	go LimiterLoop()
}

func prepareOsKite() *kite.Kite {
	kiteName := "os"
	if *flagRegion != "" {
		kiteName += "-" + *flagRegion
	}

	k := kite.New(kiteName, conf, true)

	// Default is "broker", we are going to use another one. In our case its "brokerKite"
	k.PublishExchange = conf.BrokerKite.Name

	if *flagDebug {
		kite.EnableDebug()
	}

	k.LoadBalancer = func(correlationName string, username string, deadService string) string {
		var vm *virt.VM
		if bson.IsObjectIdHex(correlationName) {
			mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
				return c.FindId(bson.ObjectIdHex(correlationName)).One(&vm)
			})
		}

		if vm == nil {
			if err := mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
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

			if err := mongodbConn.Run("jVMs", query); err != nil {
				log.LogError(err, 0, vm.Id.Hex())
			}

			return k.ServiceUniqueName
		}

		return vm.HostKite
	}

	return k
}

// handleCurrentVMS removes and unprepare any vm in the lxc dir that doesn't
// have any associated document which in mongodbConn.
func handleCurrentVMS() {
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

			if err := mongodbConn.Run("jVMs", query); err != nil || vm.HostKite != serviceUniqueName {

				log.Info("cleaning up leftover VM: '%s', vm.Hoskite: '%s', k.ServiceUniqueName: '%s', error '%v'",
					vmId, vm.HostKite, serviceUniqueName, err)

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

func startPinnedVMS() {
	mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
		iter := c.Find(bson.M{"pinnedToHost": serviceUniqueName, "alwaysOn": true}).Iter()
		for {
			var vm virt.VM
			if !iter.Next(&vm) {
				break
			}
			if err := startAndPrepareVM(&vm, nil); err != nil {
				log.LogError(err, 0)
			}
		}

		if err := iter.Close(); err != nil {
			panic(err)
		}

		return nil
	})

}

func setupSignalHandler() {
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
					bson.M{"hostKite": serviceUniqueName},
					bson.M{"$set": bson.M{"hostKite": nil}},
				) // ensure that really all are set to nil
				return err
			}

			err := mongodbConn.Run("jVMs", query)
			if err != nil {
				log.LogError(err, 0)
			}
		}

		log.Fatal()
	}()
}

// registerMethod is wrapper around our final methods. It's basically creates
// a "vos" struct and pass it to the our method. The VOS has "vm", "user" and
// "permissions" document embedded, with this info our final method has all
// the necessary needed bits.
func registerMethod(k *kite.Kite, method string, concurrent bool, callback func(*dnode.Partial, *kite.Channel, *virt.VOS) (interface{}, error)) {

	wrapperMethod := func(args *dnode.Partial, channel *kite.Channel) (methodReturnValue interface{}, methodError error) {
		// set to true when a SIGNAL is received
		if shuttingDown {
			return nil, errors.New("Kite is shutting down.")
		}

		// Needed when we oskite get closed via a SIGNAL. It waits until all methods are done.
		requestWaitGroup.Add(1)
		defer requestWaitGroup.Done()

		user, err := getUser(channel.Username)
		if err != nil {
			return nil, err
		}

		vm, err := getVM(channel.CorrelationName)
		if err != nil {
			return nil, err
		}

		log.Info("[%s] method %s get called", vm.Id.Hex(), method)

		defer func() {
			if err := recover(); err != nil {
				log.LogError(err, 1, channel.Username, channel.CorrelationName, vm.String())
				time.Sleep(time.Second) // penalty for avoiding that the client rapidly sends the request again on error
				methodError = &kite.InternalKiteError{}
			}
		}()

		// this method is special cased in oskite.go to allow foreign access,
		// that's why do not check for permisisons.
		if method == "webterm.connect" {
			return callback(args, channel, &virt.VOS{VM: vm, User: user})
		}

		// vos has now "vm", "user" and "permissions" document.
		vos, err := vm.OS(user)
		if err != nil {
			return nil, err // returns an error if the permisisons are not set for the user
		}

		// now call our final method. run forrest run ....!
		return callback(args, channel, vos)
	}

	k.Handle(method, concurrent, wrapperMethod)
}

// getVos returns a new VOS based on the given username and correlationName
// which is used to pick up the correct VM.
func getVos(username, correlationName string) (*virt.VOS, error) {
	user, err := getUser(username)
	if err != nil {
		return nil, err
	}

	vm, err := getVM(correlationName)
	if err != nil {
		return nil, err
	}

	permissions := vm.GetPermissions(user)
	if permissions == nil && user.Uid != virt.RootIdOffset {
		return nil, errors.New("Permission denied.")
	}

	return &virt.VOS{
		VM:          vm,
		User:        user,
		Permissions: permissions,
	}, nil
}

// getUser returns a new *virt.User struct based on the given username
func getUser(username string) (*virt.User, error) {
	var user *virt.User
	if err := mongodbConn.Run("jUsers", func(c *mgo.Collection) error {
		return c.Find(bson.M{"username": username}).One(&user)
	}); err != nil {
		if err != mgo.ErrNotFound {
			return nil, err
		}

		if !strings.HasPrefix(username, "guest-") {
			log.Warning("User not found: %v", username)
		}

		time.Sleep(time.Second) // to avoid rapid cycle channel loop
		return nil, &kite.WrongChannelError{}
	}

	if user.Uid < virt.UserIdOffset {
		return nil, errors.New("User with too low uid.")
	}

	return user, nil
}

// getVM returns a new virt.VM struct based on on the given correlationName.
// Here correlationName can be either the hostnameAlias or the given VM
// documents ID.
func getVM(correlationName string) (*virt.VM, error) {
	var vm *virt.VM
	query := bson.M{"hostnameAlias": correlationName}
	if bson.IsObjectIdHex(correlationName) {
		query = bson.M{"_id": bson.ObjectIdHex(correlationName)}
	}

	if err := mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
		return c.Find(query).One(&vm)
	}); err != nil {
		return nil, &VMNotFoundError{Name: correlationName}
	}

	vm.ApplyDefaults()
	return vm, nil
}

func validateVM(vm *virt.VM) error {
	if vm.Region != *flagRegion {
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

		updateErr := mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
			return c.Update(bson.M{"_id": vm.Id, "ip": nil}, bson.M{"$set": bson.M{"ip": ip}})
		})

		if updateErr != nil {
			var logVM *virt.VM
			err := mongodbConn.One("jVMs", vm.Id.Hex(), &logVM)
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
		if err := mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
			return c.Update(bson.M{"_id": vm.Id}, bson.M{"$set": bson.M{"ldapPassword": ldapPassword}})
		}); err != nil {
			panic(err)
		}
		vm.LdapPassword = ldapPassword
	}

	if vm.HostKite != serviceUniqueName {
		err := mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
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

func startAndPrepareVM(vm *virt.VM, channel *kite.Channel) error {
	err := validateVM(vm)
	if err != nil {
		return err
	}

	var info *VMInfo

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

			log.Info("VM PREPARE and START: %s [%s] - ElapsedTime: %.10f seconds.",
				vm, vm.HostnameAlias, time.Since(startTime).Seconds())
		}

		// wait until the prepareWorker has picked us and we finished
		<-wait
	}

	// if it's started already it will not do anything
	if err := vm.Start(); err != nil {
		log.LogError(err, 0)
	}

	// wait until network is up
	if err := vm.WaitForNetwork(time.Second * 5); err != nil {
		log.Error("%v", err)
	}

	info.currentHostname = vm.HostnameAlias
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

	if err := mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
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

	if err := mongodbConn.Run("counters", func(c *mgo.Collection) error {
		_, err := c.FindId(counterName).Apply(mgo.Change{Update: bson.M{"$inc": bson.M{"seq": 1}}}, &counter)
		return err
	}); err != nil {
		if err == mgo.ErrNotFound {
			mongodbConn.Run("counters", func(c *mgo.Collection) error {
				c.Insert(Counter{Name: counterName, Value: initialValue})
				return nil // ignore error and try to do atomic update again
			})

			if err := mongodbConn.Run("counters", func(c *mgo.Collection) error {
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
