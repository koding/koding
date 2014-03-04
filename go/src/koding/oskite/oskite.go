package oskite

import (
	"encoding/binary"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"koding/databases/redis"
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/kodingkite"
	"koding/oskite/ldapserver"
	"koding/tools/config"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/tools/lifecycle"
	"koding/tools/logger"
	"koding/tools/utils"
	"koding/virt"
	"math/rand"
	"net"
	"os"
	"os/signal"
	"sort"
	"strings"
	"sync"
	"syscall"
	"time"

	redigo "github.com/garyburd/redigo/redis"
	kitelib "github.com/koding/kite"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

const (
	OSKITE_NAME    = "oskite"
	OSKITE_VERSION = "0.1.4"
)

var (
	log         = logger.New(OSKITE_NAME)
	mongodbConn *mongodb.MongoDB
	conf        *config.Config

	infos            = make(map[bson.ObjectId]*VMInfo)
	infosMutex       sync.Mutex
	templateDir      = "files/templates" // should be in the same dir as the binary
	firstContainerIP net.IP
	containerSubnet  *net.IPNet
	shuttingDown     = false
	requestWaitGroup sync.WaitGroup

	prepareQueue      = make(chan *QueueJob, 1000)
	currentQueueCount AtomicInt32
	vmTimeout         time.Duration
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

type Oskite struct {
	Name     string
	Version  string
	Region   string
	LogLevel logger.Level

	ActiveVMsLimit int
	ActiveVMs      int

	ServiceUniquename string
	VmTimeout         time.Duration
	TemplateDir       string
	DisableGuest      bool

	// PrepareQueueLimit defines the number of concurrent VM preparations,
	// should be CPU + 1
	PrepareQueueLimit int
}

// QueueJob is used to append jobs to the prepareQueue.
type QueueJob struct {
	f   func() string
	msg string
}

func New(c *config.Config) *Oskite {
	conf = c
	mongodbConn = mongodb.NewMongoDB(c.Mongo)
	modelhelper.Initialize(c.Mongo)

	return &Oskite{
		Name:    OSKITE_NAME,
		Version: OSKITE_VERSION,
	}
}

func (o *Oskite) Run() {

	log.SetLevel(o.LogLevel)

	log.Info("Using default VM timeout: %v", o.VmTimeout)

	// TODO: get rid of this after solving info problem
	vmTimeout = o.VmTimeout

	if o.Region == "" {
		panic("region is not set for Oskite")
	}

	if o.ActiveVMsLimit == 0 {
		panic("active VMS limit is not defined.")
	}

	if o.PrepareQueueLimit == 0 {
		panic("prepare queue is not set")
	}

	if o.TemplateDir != "" {
		templateDir = o.TemplateDir
	}

	// set seed for even randomness, needed for randomMinutes() function.
	rand.Seed(time.Now().UnixNano())

	o.initializeSettings()

	// startPrepareWorkers starts multiple workers (based on prepareQueueLimit)
	// that accepts vmPrepare/vmStart functions.
	for i := 0; i < o.PrepareQueueLimit; i++ {
		go prepareWorker(i)
	}

	k := o.prepareOsKite()

	o.ServiceUniquename = k.ServiceUniqueName

	o.runNewKite()
	o.handleCurrentVMS()   // handle leftover VMs
	o.startPinnedVMS()     // start pinned always-on VMs
	o.setupSignalHandler() // handle SIGUSR1 and other signals.

	// register current client-side methods
	o.registerVmMethod(k, "vm.start", false, vmStartOld)
	o.registerVmMethod(k, "vm.shutdown", false, vmShutdownOld)
	o.registerVmMethod(k, "vm.unprepare", false, vmUnprepareOld)
	o.registerVmMethod(k, "vm.stop", false, vmStopOld)
	o.registerVmMethod(k, "vm.reinitialize", false, vmReinitializeOld)
	o.registerVmMethod(k, "vm.info", false, vmInfoOld)
	o.registerVmMethod(k, "vm.resizeDisk", false, vmResizeDiskOld)
	o.registerVmMethod(k, "vm.createSnapshot", false, vmCreateSnapshotOld)
	o.registerVmMethod(k, "spawn", true, spawnFuncOld)
	o.registerVmMethod(k, "exec", true, execFuncOld)

	o.registerVmMethod(k, "oskite.Info", true, o.oskiteInfo)
	o.registerVmMethod(k, "oskite.All", true, oskiteAll)

	syscall.Umask(0) // don't know why richard calls this
	o.registerVmMethod(k, "fs.readDirectory", false, fsReadDirectoryOld)
	o.registerVmMethod(k, "fs.glob", false, fsGlobOld)
	o.registerVmMethod(k, "fs.readFile", false, fsReadFileOld)
	o.registerVmMethod(k, "fs.writeFile", false, fsWriteFileOld)
	o.registerVmMethod(k, "fs.ensureNonexistentPath", false, fsUniquePathOld)
	o.registerVmMethod(k, "fs.getInfo", false, fsGetInfoOld)
	o.registerVmMethod(k, "fs.setPermissions", false, fsSetPermissionsOld)
	o.registerVmMethod(k, "fs.remove", false, fsRemoveOld)
	o.registerVmMethod(k, "fs.rename", false, fsRenameOld)
	o.registerVmMethod(k, "fs.createDirectory", false, fsCreateDirectoryOld)

	o.registerVmMethod(k, "app.install", false, appInstall)
	o.registerVmMethod(k, "app.download", false, appDownload)
	o.registerVmMethod(k, "app.publish", false, appPublish)
	o.registerVmMethod(k, "app.skeleton", false, appSkeleton)

	// this method is special cased in oskite.go to allow foreign access
	o.registerVmMethod(k, "webterm.connect", false, webtermConnect)
	o.registerVmMethod(k, "webterm.getSessions", false, webtermGetSessions)

	o.registerVmMethod(k, "s3.store", true, s3Store)
	o.registerVmMethod(k, "s3.delete", true, s3Delete)

	go o.oskiteRedis(k.ServiceUniqueName)

	log.Info("Oskite started. Go!")
	k.Run()

}

var oskitesMu sync.Mutex
var oskites = make(map[string]*OskiteInfo)

func (o *Oskite) oskiteRedis(serviceUniquename string) {
	session, err := redis.NewRedisSession(conf.Redis)
	if err != nil {
		log.Error("redis SADD kontainers. err: %v", err.Error())
	}
	session.SetPrefix("oskite")

	prefix := "oskite:" + conf.Environment + ":"
	kontainerSet := "kontainers-" + conf.Environment

	log.Info("Connected to Redis with %s", prefix+serviceUniquename)

	_, err = redigo.Int(session.Do("SADD", kontainerSet, prefix+serviceUniquename))
	if err != nil {
		log.Error("redis SADD kontainers. err: %v", err.Error())
	}

	// update regularly our VMS info
	go func() {
		expireDuration := time.Second * 5
		for _ = range time.Tick(2 * time.Second) {
			key := prefix + serviceUniquename
			oskiteInfo := o.GetOskiteInfo()

			if _, err := session.Do("HMSET", redigo.Args{key}.AddFlat(oskiteInfo)...); err != nil {
				log.Error("redis HMSET err: %v", err.Error())
			}

			reply, err := redigo.Int(session.Do("EXPIRE", key, expireDuration.Seconds()))
			if err != nil {
				log.Error("redis SET Expire %v. reply: %v err: %v", key, reply, err.Error())
			}
		}
	}()

	// get oskite statuses from others every 2 seconds
	for _ = range time.Tick(2 * time.Second) {
		kontainers, err := redigo.Strings(session.Do("SMEMBERS", kontainerSet))
		if err != nil {
			log.Error("redis SMEMBER kontainers. err: %v", err.Error())
		}

		for _, kontainerHostname := range kontainers {
			// convert to serviceUniqueName formst
			remoteOskite := strings.TrimPrefix(kontainerHostname, prefix)

			values, err := redigo.Values(session.Do("HGETALL", kontainerHostname))
			if err != nil {
				log.Error("redis HTGETALL %s. err: %v", kontainerHostname, err.Error())

				// kontainer might be dead, key gets than expired, continue with the next one

				oskitesMu.Lock()
				delete(oskites, remoteOskite)
				oskitesMu.Unlock()
				continue
			}

			oskiteInfo := new(OskiteInfo)
			if err := redigo.ScanStruct(values, oskiteInfo); err != nil {
				log.Error("redis ScanStruct err: %v", err.Error())
			}

			log.Debug("%s: %+v", kontainerHostname, oskiteInfo)

			oskitesMu.Lock()
			oskites[remoteOskite] = oskiteInfo
			oskitesMu.Unlock()
		}
	}
}

func lowestOskiteLoad() (serviceUniquename string) {
	oskitesMu.Lock()
	defer oskitesMu.Unlock()

	oskitesSlice := make([]*OskiteInfo, 0, len(oskites))

	for s, v := range oskites {
		v.ServiceUniquename = s
		oskitesSlice = append(oskitesSlice, v)
	}

	sort.Sort(ByVM(oskitesSlice))

	middle := len(oskitesSlice) / 2
	if middle == 0 {
		return ""
	}

	// return randomly one of the lowest
	l := oskitesSlice[rand.Intn(middle)]

	// also pick up the highest to log information
	h := oskitesSlice[len(oskitesSlice)-1]

	log.Info("oskite picked up as lowest load %s with %d VMs (highest was: %d / %s)",
		l.ServiceUniquename, l.ActiveVMs, h.ActiveVMs, h.ServiceUniquename)

	return l.ServiceUniquename

}

func (o *Oskite) runNewKite() {
	log.Info("Run newkite.")
	k := kodingkite.New(
		conf,
		kitelib.Options{
			Kitename: OSKITE_NAME,
			Version:  "0.0.1",
			Port:     "5000",
			Region:   o.Region,
		},
	)

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

		err = o.validateVM(&vm)
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
			vm.Prepare(false)
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
	log.SetLevel(o.LogLevel)
}

func (o *Oskite) initializeSettings() {
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

func (o *Oskite) prepareOsKite() *kite.Kite {
	log.Info("Kite.go preperation started")
	kiteName := "os"
	if o.Region != "" {
		kiteName += "-" + o.Region
	}

	k := kite.New(kiteName, conf, true)

	// Default is "broker", we are going to use another one. In our case its "brokerKite"
	k.PublishExchange = conf.BrokerKite.Name

	if o.LogLevel == logger.DEBUG {
		kite.EnableDebug()
	}

	k.LoadBalancer = func(correlationName string, username string, deadService string) string {
		blog := func(v interface{}) {
			log.Info("oskite loadbalancer for [correlationName: '%s' user: '%s' deadService: '%s'] results in --> %v.", correlationName, username, deadService, v)
		}

		resultOskite := o.ServiceUniquename
		lowestOskite := lowestOskiteLoad()
		if lowestOskite != "" {
			if deadService == lowestOskite {
				resultOskite = o.ServiceUniquename
			} else {
				resultOskite = lowestOskite
			}
		}

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
				blog(fmt.Sprintf("no hostnameAlias found, returning %s", resultOskite))
				return resultOskite // no vm was found, return this oskite
			}
		}

		if vm.PinnedToHost != "" {
			blog(fmt.Sprintf("returning pinnedHost '%s'", vm.PinnedToHost))
			return vm.PinnedToHost
		}

		if vm.HostKite == "" {
			blog(fmt.Sprintf("hostkite is empty returning '%s'", resultOskite))
			return resultOskite
		}

		// maintenance and banned will be handled again in valideVM() function,
		// which will return a permission error.
		if vm.HostKite == "(maintenance)" || vm.HostKite == "(banned)" {
			blog(fmt.Sprintf("hostkite is %s returning '%s'", vm.HostKite, resultOskite))
			return resultOskite
		}

		// Set hostkite to nil if we detect a dead service. On the next call,
		// Oskite will point to an health service in validateVM function()
		// because it will detect that the hostkite is nil and change it to the
		// healthy service given by the client, which is the returned
		// k.ServiceUniqueName.
		if vm.HostKite == deadService {
			blog(fmt.Sprintf("dead service detected %s returning '%s'", vm.HostKite, o.ServiceUniquename))
			if err := mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
				return c.Update(bson.M{"_id": vm.Id}, bson.M{"$set": bson.M{"hostKite": nil}})
			}); err != nil {
				log.LogError(err, 0, vm.Id.Hex())
			}

			return resultOskite
		}

		blog(fmt.Sprintf("returning existing hostkite '%s'", vm.HostKite))
		return vm.HostKite
	}

	return k
}

// handleCurrentVMS removes and unprepare any vm in the lxc dir that doesn't
// have any associated document which in mongodbConn.
func (o *Oskite) handleCurrentVMS() {
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

			if err := mongodbConn.Run("jVMs", query); err != nil || vm.HostKite != o.ServiceUniquename {
				log.Info("cleaning up leftover VM: '%s', vm.Hoskite: '%s', k.ServiceUniqueName: '%s', error '%v'",
					vmId, vm.HostKite, o.ServiceUniquename, err)

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

	log.Info("VMs in /var/lib/lxc are finished.")
}

func (o *Oskite) startPinnedVMS() {
	log.Info("Starting pinned hosts, if any...")
	mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
		iter := c.Find(bson.M{"pinnedToHost": o.ServiceUniquename, "alwaysOn": true}).Iter()
		for {
			var vm virt.VM
			if !iter.Next(&vm) {
				break
			}
			if err := o.startVM(&vm, nil); err != nil {
				log.LogError(err, 0)
			}
		}

		if err := iter.Close(); err != nil {
			panic(err)
		}

		return nil
	})
}

func (o *Oskite) setupSignalHandler() {
	log.Info("Setting up signal handler")
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
				prepareQueue <- &QueueJob{
					msg: "vm unprepare because of shutdown oskite " + info.vm.HostnameAlias,
					f: func() string {
						info.unprepareVM()
						return fmt.Sprintf("shutting down %s", info.vm.Id.Hex())
					},
				}
			}

			query := func(c *mgo.Collection) error {
				_, err := c.UpdateAll(
					bson.M{"hostKite": o.ServiceUniquename},
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

func (o *Oskite) registerVmMethod(k *kite.Kite, method string, concurrent bool, callback func(*dnode.Partial, *kite.Channel, *virt.VOS) (interface{}, error)) {

	wrapperMethod := func(args *dnode.Partial, channel *kite.Channel) (methodReturnValue interface{}, methodError error) {

		if shuttingDown {
			return nil, errors.New("Kite is shutting down.")
		}

		requestWaitGroup.Add(1)
		defer requestWaitGroup.Done()

		if shuttingDown { // check second time after sync to avoid additional mutex
			return nil, errors.New("Kite is shutting down.")
		}

		if o.ActiveVMsLimit <= currentVMS() {
			return nil, fmt.Errorf("Maximum capacity of %s has been reached.", o.ActiveVMsLimit)
		}

		user, err := o.getUser(channel.Username)
		if err != nil {
			return nil, err
		}

		vm, err := o.getVM(channel)
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

				if err := mongodbConn.Run("jUsers", func(c *mgo.Collection) error {
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

		if err := o.startVM(vm, channel); err != nil {
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
	}

	k.Handle(method, concurrent, wrapperMethod)
}

func (o *Oskite) getUser(username string) (*virt.User, error) {
	// Do not create guest vms if its turned of
	if o.DisableGuest && strings.HasPrefix(username, "guest-") {
		return nil, errors.New("vm creation for guests are disabled.")
	}

	var user *virt.User
	if err := mongodbConn.Run("jUsers", func(c *mgo.Collection) error {
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

func (o *Oskite) getVM(channel *kite.Channel) (*virt.VM, error) {
	var vm *virt.VM
	query := bson.M{"hostnameAlias": channel.CorrelationName}
	if bson.IsObjectIdHex(channel.CorrelationName) {
		query = bson.M{"_id": bson.ObjectIdHex(channel.CorrelationName)}
	}

	if info, _ := channel.KiteData.(*VMInfo); info != nil {
		query = bson.M{"_id": info.vm.Id}
	}

	if err := mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
		return c.Find(query).One(&vm)
	}); err != nil {
		return nil, &VMNotFoundError{Name: channel.CorrelationName}
	}

	return vm, nil
}

func (o *Oskite) validateVM(vm *virt.VM) error {
	if vm.Region != o.Region {
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

	if vm.HostKite != o.ServiceUniquename {
		err := mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
			return c.Update(bson.M{"_id": vm.Id, "hostKite": nil}, bson.M{"$set": bson.M{"hostKite": o.ServiceUniquename}})
		})
		if err != nil {
			time.Sleep(time.Second) // to avoid rapid cycle channel loop
			return &kite.WrongChannelError{}
		}

		vm.HostKite = o.ServiceUniquename
	}

	return nil
}

func (o *Oskite) startVM(vm *virt.VM, channel *kite.Channel) error {
	err := o.validateVM(vm)
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
		done := make(chan struct{}, 1)

		prepareQueue <- &QueueJob{
			msg: "vm prepare and restart " + vm.HostnameAlias,
			f: func() string {
				startTime := time.Now()

				// prepare first
				vm.Prepare(false)

				// start it
				if err := vm.Start(); err != nil {
					log.LogError(err, 0)
				}

				// wait until network is up
				if err := vm.WaitForNetwork(time.Second * 5); err != nil {
					log.Error("%v", err)
				}

				res := fmt.Sprintf("VM PREPARE and START: %s [%s] - ElapsedTime: %.10f seconds.",
					vm, vm.HostnameAlias, time.Since(startTime).Seconds())

				info.currentHostname = vm.HostnameAlias

				done <- struct{}{}
				return res
			},
		}

		log.Info("putting %s into queue. total vms in queue: %d of %d",
			vm.HostnameAlias, currentQueueCount.Get(), len(prepareQueue))

		// wait until the prepareWorker has picked us and we finished
		// to return something to the client
		<-done
	}

	return nil
}

// prepareWorker listens from prepareQueue channel and runs the functions it receives
func prepareWorker(id int) {
	for job := range prepareQueue {
		currentQueueCount.Add(1)

		log.Info(fmt.Sprintf("Queue %d: processing new job [%s]", id, time.Now().Format(time.StampMilli)))

		done := make(chan struct{}, 1)
		go func() {
			startTime := time.Now()
			res := job.f() // execute our function
			log.Info(fmt.Sprintf("Queue %d: elapsed time %s res: %s", id, time.Since(startTime), res))
			done <- struct{}{}
		}()

		select {
		case <-done:
			log.Info(fmt.Sprintf("Queue %d: done for job: %s", id, job.msg))
		case <-time.After(time.Second * 60):
			log.Info(fmt.Sprintf("Queue %d: timed out after 60 seconds for job: %s", id, job.msg))
		}

		currentQueueCount.Add(-1)
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

// randomMinutes returns a random duration between [0,n] in minutes. It panics if n <=  0.
func randomMinutes(n int64) time.Duration { return time.Minute * time.Duration(rand.Int63n(n)) }

func (info *VMInfo) startTimeout() {
	if info.useCounter != 0 || info.vm.AlwaysOn {
		return
	}

	// Shut down the VM (unprepareVM does it.) The timeout is calculated as:
	// * 5  Minutes from kite.go
	// * 50 Minutes pre-defined timeout
	// * 5  Minutes after we give warning
	// * [0, 30] random duration to avoid hickups during mass unprepares
	// In Total it's [60, 90] minutes.
	totalTimeout := vmTimeout + randomMinutes(30)
	log.Info("Timer is started. VM %s will be shut down in %s minutes",
		info.vm.Id.Hex(), totalTimeout)

	info.timeout = time.AfterFunc(totalTimeout, func() {
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

			prepareQueue <- &QueueJob{
				msg: "vm unprepare " + info.vm.HostnameAlias,
				f: func() string {
					info.unprepareVM()
					return fmt.Sprintf("shutting down %s after %s", info.vm.Id.Hex(), totalTimeout)
				},
			}

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
