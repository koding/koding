package oskite

import (
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/tools/config"
	"koding/tools/logger"
	"math/rand"
	"syscall"
	"time"
)

const (
	OSKITE_NAME    = "oskite"
	OSKITE_VERSION = "0.1.3"
)

var (
	log         = logger.New(OSKITE_NAME)
	mongodbConn *mongodb.MongoDB
    conf        *config.Config
)

type Oskite struct {
	Version           string
	ActiveVMs         int
	ServiceUniquename string
	VmTimeout         time.Duration
	TemplateDir       string
	LogLevel          logger.Level

	// PrepareQueueLimit defines the number of concurrent VM preparations,
	// should be CPU + 1
	PrepareQueueLimit int
	prepareQueue      chan *QueueJob
	currentQueueCount AtomicInt32
}

// QueueJob is used to append jobs to the prepareQueue.
type QueueJob struct {
	f   func() string
	msg string
}

func New(conf *config.Config) *Oskite {

    conf =
	mongodbConn = mongodb.NewMongoDB(conf.Mongo)
	modelhelper.Initialize(conf.Mongo)

	return &Oskite{
		Name:         OSKITE_NAME,
		Version:      OSKITE_VERSION,
		prepareQueue: make(chan *QueueJob, 1000),
	}
}

func (o *Oskite) Run() {
	// set seed for even randomness, needed for randomMinutes() function.
	rand.Seed(time.Now().UnixNano())

	initializeSettings()

	// startPrepareWorkers starts multiple workers (based on prepareQueueLimit)
	// that accepts vmPrepare/vmStart functions.
	for i := 0; i < prepareQueueLimit; i++ {
		go prepareWorker(i)
	}

	k := prepareOsKite()
	log.Info("Kite.go preperation is done")

	runNewKite(k.ServiceUniqueName)
	log.Info("Run newkite is finished.")

	handleCurrentVMS(k) // handle leftover VMs
	log.Info("VMs in /var/lib/lxc are finished.")

	startPinnedVMS(k) // start pinned always-on VMs
	log.Info("Starting pinned hosts, if any...")

	setupSignalHandler(k) // handle SIGUSR1 and other signals.
	log.Info("Setting up signal handler")

	// register current client-side methods
	registerVmMethod(k, "vm.start", false, vmStart)
	registerVmMethod(k, "vm.shutdown", false, vmShutdown)
	registerVmMethod(k, "vm.unprepare", false, vmUnprepare)
	registerVmMethod(k, "vm.stop", false, vmStop)
	registerVmMethod(k, "vm.reinitialize", false, vmReinitialize)
	registerVmMethod(k, "vm.info", false, vmInfo)
	registerVmMethod(k, "vm.resizeDisk", false, vmResizeDisk)
	registerVmMethod(k, "vm.createSnapshot", false, vmCreateSnaphost)
	registerVmMethod(k, "spawn", true, spawnFunc)
	registerVmMethod(k, "exec", true, execFunc)

	registerVmMethod(k, "oskite.Info", true, oskiteInfo)
	registerVmMethod(k, "oskite.All", true, oskiteAll)

	syscall.Umask(0) // don't know why richard calls this
	registerVmMethod(k, "fs.readDirectory", false, fsReadDirectory)
	registerVmMethod(k, "fs.glob", false, fsGlob)
	registerVmMethod(k, "fs.readFile", false, fsReadFile)
	registerVmMethod(k, "fs.writeFile", false, fsWriteFile)
	registerVmMethod(k, "fs.ensureNonexistentPath", false, fsEnsureNonexistentPath)
	registerVmMethod(k, "fs.getInfo", false, fsGetInfo)
	registerVmMethod(k, "fs.setPermissions", false, fsSetPermissions)
	registerVmMethod(k, "fs.remove", false, fsRemove)
	registerVmMethod(k, "fs.rename", false, fsRename)
	registerVmMethod(k, "fs.createDirectory", false, fsCreateDirectory)

	registerVmMethod(k, "app.install", false, appInstall)
	registerVmMethod(k, "app.download", false, appDownload)
	registerVmMethod(k, "app.publish", false, appPublish)
	registerVmMethod(k, "app.skeleton", false, appSkeleton)

	// this method is special cased in oskite.go to allow foreign access
	registerVmMethod(k, "webterm.connect", false, webtermConnect)
	registerVmMethod(k, "webterm.getSessions", false, webtermGetSessions)

	registerVmMethod(k, "s3.store", true, s3Store)
	registerVmMethod(k, "s3.delete", true, s3Delete)

	go oskiteRedis(k.ServiceUniqueName)

	log.Info("Oskite started. Go!")
	k.Run()

}
