package app

import (
	"bytes"
	"errors"
	"fmt"
	"log"
	"net"
	"net/url"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"sync"
	"time"

	"koding/api"
	"koding/api/apiutil"
	"koding/api/presence"
	"koding/httputil"
	cfg "koding/kites/config"
	"koding/kites/config/configstore"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/team"
	"koding/kites/metrics"
	"koding/klient/client"
	"koding/klient/collaboration"
	"koding/klient/command"
	konfig "koding/klient/config"
	"koding/klient/control"
	"koding/klient/fs"
	"koding/klient/info"
	"koding/klient/info/publicip"
	"koding/klient/logfetcher"
	mclient "koding/klient/machine/client"
	"koding/klient/machine/index"
	"koding/klient/machine/machinegroup"
	"koding/klient/machine/mount/notify/fuse"
	"koding/klient/machine/mount/sync/rsync"
	kos "koding/klient/os"
	"koding/klient/sshkeys"
	"koding/klient/storage"
	"koding/klient/terminal"
	"koding/klient/tunnel"
	"koding/klient/uploader"
	"koding/klient/usage"
	"koding/klient/vagrant"
	"koding/klientctl/daemon"
	"koding/logrotate"

	endpointkloud "koding/klientctl/endpoint/kloud"

	"github.com/boltdb/bolt"
	"github.com/koding/kite"
	"github.com/koding/kite/kontrol/onceevery"
	kiteproto "github.com/koding/kite/protocol"
	"github.com/koding/logging"
)

// Klient is the central app which provides all available methods.
type Klient struct {
	// kite defines the server running and powering Klient.
	kite *kite.Kite

	// collab is used to store authorized third party users and allows them to
	// use the available methods. It provides methods to add or remove users
	// from the storage
	collab *collaboration.Collaboration

	// collabCloser is used to de-register third party users after some
	// specific time when klient's root user ends his connection.
	collabCloser *DeferTime

	storage *storage.Storage

	// terminal provides wmethods
	terminal terminal.Terminal

	// vagrant handlers
	vagrant *vagrant.Handlers

	// docker provides the docker related methods.
	// docker *docker.Docker

	// usage counts and tracks all called metrics. It also provides a method
	// that return those informations
	usage *usage.Usage

	// tunnel establishes a tunnel connection when we have no public IP
	// addresses or the connection is behind a firewall.
	tunnel *tunnel.Tunnel

	metrics *metrics.Metrics
	log     kite.Logger

	// config stores all necessary configuration needed for Klient to work.
	// It's supplied with the NewKlient() function.
	config *KlientConfig

	// machines manages a group of machines that can be seen or used by Klient.
	//
	// TODO(ppknap): this field is going to store all machine operations.
	machines *machinegroup.Group

	// updater polls s3://latest-version.txt with config.UpdateInterval
	// and updates current binary if version is never than config.Version.
	updater *Updater

	// uploader streams logs to an S3 bucket
	uploader       *uploader.Uploader
	logUploadDelay time.Duration

	// publicIP is a cached public IP address of the klient.
	publicIP net.IP

	presence      *presence.Client
	presenceEvery *onceevery.OnceEvery
	kloud         *apiutil.LazyKite

	// Team related fields.
	// TODO(ppknap): move this to separate package.
	teamMu        sync.Mutex
	team          *team.Team
	teamUpdatedAt time.Time
}

// KlientConfig defines a Klient's config
type KlientConfig struct {
	Name    string
	Version string

	IP          string
	Port        int
	Environment string
	Region      string
	RegisterURL string
	KontrolURL  string
	Debug       bool

	ScreenrcPath string
	ScreenTerm   string

	UpdateInterval time.Duration
	UpdateURL      string

	VagrantHome string

	TunnelName    string
	TunnelKiteURL string

	NoTunnel bool
	NoProxy  bool
	NoExit   bool

	Autoupdate bool

	LogBucketRegion   string
	LogBucketName     string
	LogUploadInterval time.Duration
	LogLevel          kite.Level

	Metadata     string
	MetadataFile string
}

func (conf *KlientConfig) logBucketName() string {
	if conf.LogBucketName != "" {
		return conf.LogBucketName
	}

	return konfig.Konfig.PublicBucketName
}

func (conf *KlientConfig) logBucketRegion() string {
	if conf.LogBucketRegion != "" {
		return conf.LogBucketRegion
	}

	return konfig.Konfig.PublicBucketRegion
}

// NewKlient returns a new Klient instance
func NewKlient(conf *KlientConfig) (*Klient, error) {
	// this is our main reference to count and measure metrics for the klient
	// we count only those methods, please add/remove methods here that will
	// reset the timer of a klient.
	usg := usage.NewUsage(map[string]bool{
		"fs.readDirectory":     true,
		"fs.glob":              true,
		"fs.readFile":          true,
		"fs.writeFile":         true,
		"fs.uniquePath":        true,
		"fs.getInfo":           true,
		"fs.setPermissions":    true,
		"fs.remove":            true,
		"fs.rename":            true,
		"fs.createDirectory":   true,
		"fs.move":              true,
		"fs.copy":              true,
		"webterm.getSessions":  true,
		"webterm.connect":      true,
		"webterm.killSession":  true,
		"webterm.killSessions": true,
		"webterm.rename":       true,
		"exec":                 true,
		"klient.share":         true,
		"klient.unshare":       true,
		"klient.shared":        true,
		"sshkeys.List":         true,
		"sshkeys.Add":          true,
		"sshkeys.Delete":       true,
		"storage.Get":          true,
		"storage.Set":          true,
		"storage.Delete":       true,
		"log.upload":           true,
		// "docker.create":       true,
		// "docker.connect":      true,
		// "docker.stop":         true,
		// "docker.start":        true,
		// "docker.remove":       true,
		// "docker.list":         true,
	})

	// TODO(rjeczalik): Once klient installation method is reworked,
	// ensure flags are stored alongside konfig and do not
	// overwrite konfig here.
	if conf.KontrolURL != "" {
		konfig.Konfig.KontrolURL = conf.KontrolURL
	}

	// NOTE(rjeczalik): For backward-compatibility with old klient,
	// remove once not needed.
	if u, err := url.Parse(konfig.Konfig.KontrolURL); err == nil && konfig.Konfig.KontrolURL != "" {
		u.Path = ""
		konfig.Konfig.Endpoints.Koding = cfg.NewEndpointURL(u)
	}

	if conf.TunnelKiteURL != "" {
		u, err := url.Parse(conf.TunnelKiteURL)
		if err != nil {
			return nil, err
		}

		konfig.Konfig.Endpoints.Tunnel.Public.URL = u
	}

	k := newKite(conf)

	term := terminal.New(k.Log, conf.ScreenrcPath, usg.Reset)

	db, err := openBoltDB(configstore.CacheOptions("klient"))
	if err != nil {
		k.Log.Warning("Couldn't open BoltDB: %s", err)
	}

	m, err := metrics.NewWithDB(db, "klient")
	if err != nil {
		return nil, err
	}

	// consume kd events
	go metrics.StartCron(endpointkloud.DefaultClient, logging.NewCustom("klient-cron", conf.Debug))
	// consume klient events
	go metrics.StartCronWithMetrics(endpointkloud.DefaultClient, logging.NewCustom("klient-cron", conf.Debug), m)

	up := uploader.New(&uploader.Options{
		KeygenURL: konfig.Konfig.Endpoints.Kloud().Public.String(),
		Kite:      k,
		Bucket:    conf.logBucketName(),
		Region:    conf.logBucketRegion(),
		DB:        db,
		Log:       k.Log,
	})

	vagrantOpts := &vagrant.Options{
		Home:   conf.VagrantHome,
		DB:     db, // nil is ok, fallbacks to in-memory storage
		Log:    k.Log,
		Debug:  conf.Debug,
		Output: up.Output,
	}

	tunOpts := &tunnel.Options{
		DB:            db,
		Log:           k.Log,
		Kite:          k,
		NoProxy:       conf.NoProxy,
		TunnelKiteURL: konfig.Konfig.Endpoints.Tunnel.Public.String(),
	}

	t, err := tunnel.New(tunOpts)
	if err != nil {
		return nil, err
	}

	if conf.UpdateInterval < time.Minute {
		k.Log.Warning("Update interval can't be less than one minute. Setting to one minute.")
		conf.UpdateInterval = time.Minute
	}

	// TODO(rjeczalik): Enable after TMS-848.
	// mountEvents := make(chan *mount.Event)

	machinesOpts := &machinegroup.Options{
		Storage:         storage.NewEncodingStorage(db, []byte("machines")),
		Builder:         mclient.NewKiteBuilder(k),
		NotifyBuilder:   fuse.Builder,
		SyncBuilder:     rsync.Builder{},
		DynAddrInterval: 2 * time.Second,
		PingInterval:    15 * time.Second,
		WorkDir:         cfg.KodingMounts(),
	}

	machines, err := machinegroup.New(machinesOpts)
	if err != nil {
		k.Log.Fatal("Cannot initialize machine group: %s", err)
	}

	c := k.NewClient(konfig.Konfig.Endpoints.Kloud().Public.String())
	c.Auth = &kite.Auth{
		Type: "kiteKey",
		Key:  k.Config.KiteKey,
	}
	c.Reconnect = true

	kloud := &apiutil.LazyKite{
		Client: c,
	}

	restClient := httputil.Client(konfig.Konfig.Debug)
	restClient.Transport = &api.Transport{
		RoundTripper: restClient.Transport,
		AuthFunc: (&apiutil.KloudAuth{
			Kite: kloud,
			Storage: &apiutil.Storage{
				Cache: &cfg.Cache{
					EncodingStorage: storage.NewEncodingStorage(db, []byte("klient")),
				},
			},
		}).Auth,
		Log: k.Log.(logging.Logger),
	}

	kl := &Klient{
		kite:    k,
		collab:  collaboration.New(db), // nil is ok, fallbacks to in memory storage
		storage: storage.New(db),       // nil is ok, fallbacks to in memory storage
		tunnel:  t,
		vagrant: vagrant.NewHandlers(vagrantOpts),
		// docker:   docker.New("unix://var/run/docker.sock", k.Log),
		terminal: term,
		usage:    usg,
		log:      k.Log,
		config:   conf,
		uploader: up,
		machines: machines,
		updater: &Updater{
			Endpoint:       conf.UpdateURL,
			Interval:       conf.UpdateInterval,
			CurrentVersion: conf.Version,
			KontrolURL:     k.Config.KontrolURL,
			Log:            k.Log,
		},
		logUploadDelay: 3 * time.Minute,
		presence: &presence.Client{
			Endpoint: konfig.Konfig.Endpoints.Social().Public.WithPath("presence").URL,
			Client:   restClient,
		},
		presenceEvery: onceevery.New(1 * time.Hour),
		kloud:         kloud,
		metrics:       m,
	}

	kl.kite.OnRegister(kl.updateKiteKey)

	// Close all active sessions of the current. Do not close it immediately,
	// instead of give some time so users can safely exit. If the user
	// reconnects again the timer will be stopped so we don't unshare for
	// network hiccups accidentally.
	kl.collabCloser = NewDeferTime(time.Minute, func() {
		sharedUsers, err := kl.collab.GetAll()
		if err != nil {
			kl.log.Warning("Couldn't unshare users: %s", err)
			return
		}

		if len(sharedUsers) == 0 {
			return
		}

		kl.log.Info("Unsharing users '%s'", sharedUsers)
		for user, option := range sharedUsers {
			// dont touch permanent users
			if option.Permanent {
				kl.log.Info("User is permanent, avoiding it: %q", user)
				continue
			}

			if err := kl.collab.Delete(user); err != nil {
				kl.log.Warning("Couldn't delete user from storage: %s", err)
			}
			kl.terminal.CloseSessions(user)
		}
	})

	// This is important, don't forget it
	kl.RegisterMethods()

	return kl, nil
}

// Kite returns the underlying Kite instance.
func (k *Klient) Kite() *kite.Kite {
	return k.kite
}

// RegisterMethods registers all public available methods
func (k *Klient) RegisterMethods() {
	// don't allow anyone to call a method if we are during an update.
	k.kite.PreHandleFunc(func(r *kite.Request) (interface{}, error) {
		// Koding (kloud) connects to much, don't display it.
		if r.Username != "koding" && !k.debug() {
			k.log.Info("Kite '%s/%s/%s' called method: '%s'",
				r.Username, r.Client.Environment, r.Client.Name, r.Method)
		}

		k.updater.Wait.Wait()

		return true, nil
	})

	k.kite.PreHandleFunc(k.checkAuth)

	// Metrics, is used by Kloud to get usage so Kloud can stop free VMs
	k.kite.PreHandleFunc(k.usage.Counter) // we measure every incoming request
	k.handleFunc("klient.usage", k.usage.Current)

	// klient os method(s)
	k.handleWithSub("os.home", kos.Home)
	k.handleWithSub("os.currentUsername", kos.CurrentUsername)
	k.handleWithSub("os.exec", kos.Exec)
	k.handleWithSub("os.kill", kos.Kill)

	// Klient Info method(s)
	k.handleWithSub("klient.info", info.Info)

	// Collaboration, is used by our Koding.com browser client.
	k.handleFunc("klient.disable", control.Disable)
	k.handleFunc("klient.share", k.collab.Share)
	k.handleFunc("klient.unshare", k.collab.Unshare)
	k.handleFunc("klient.shared", k.collab.Shared)

	// SSH keys
	k.handleWithSub("sshkeys.list", sshkeys.List)
	k.handleWithSub("sshkeys.add", sshkeys.Add)
	k.handleWithSub("sshkeys.delete", sshkeys.Delete)

	// Storage
	k.handleFunc("storage.set", k.storage.SetValue)
	k.handleFunc("storage.get", k.storage.GetValue)
	k.handleFunc("storage.delete", k.storage.DeleteValue)

	// Logfetcher
	k.handleFunc("log.tail", logfetcher.Tail)

	// Filesystem
	k.handleWithSub("fs.readDirectory", fs.ReadDirectory)
	k.handleWithSub("fs.glob", fs.Glob)
	k.handleWithSub("fs.readFile", fs.ReadFile)
	k.handleWithSub("fs.writeFile", fs.WriteFile)
	k.handleWithSub("fs.uniquePath", fs.UniquePath)
	k.handleWithSub("fs.getInfo", fs.GetInfo)
	k.handleWithSub("fs.setPermissions", fs.SetPermissions)
	k.handleWithSub("fs.remove", fs.Remove)
	k.handleWithSub("fs.rename", fs.Rename)
	k.handleWithSub("fs.createDirectory", fs.CreateDirectory)
	k.handleWithSub("fs.move", fs.Move)
	k.handleWithSub("fs.copy", fs.Copy)
	k.handleWithSub("fs.getDiskInfo", fs.GetDiskInfo)
	k.handleWithSub("fs.getPathSize", fs.GetPathSize)
	k.handleWithSub("fs.abs", fs.KiteHandlerAbs())

	// Machine group handlers.
	k.handleFunc("machine.create", machinegroup.KiteHandlerCreate(k.machines))
	k.handleFunc("machine.id", machinegroup.KiteHandlerID(k.machines))
	k.handleFunc("machine.identifier.list", machinegroup.KiteHandlerIdentifierList(k.machines))
	k.handleFunc("machine.ssh", machinegroup.KiteHandlerSSH(k.machines))
	k.handleFunc("machine.mount.head", machinegroup.KiteHandlerHeadMount(k.machines))
	k.handleFunc("machine.mount.add", machinegroup.KiteHandlerAddMount(k.machines))
	k.handleFunc("machine.mount.updateIndex", machinegroup.KiteHandlerUpdateIndex(k.machines))
	k.handleFunc("machine.mount.list", machinegroup.KiteHandlerListMount(k.machines))
	k.handleFunc("machine.mount.inspect", machinegroup.KiteHandlerInspectMount(k.machines))
	k.handleFunc("machine.mount.waitIdle", k.machines.HandleWaitIdle)
	k.handleFunc("machine.mount.id", machinegroup.KiteHandlerMountID(k.machines))
	k.handleFunc("machine.mount.identifier.list", machinegroup.KiteHandlerMountIdentifierList(k.machines))
	k.handleFunc("machine.mount.manage", machinegroup.KiteHandlerManageMount(k.machines))
	k.handleFunc("machine.umount", machinegroup.KiteHandlerUmount(k.machines))
	k.handleFunc("machine.cp", machinegroup.KiteHandlerCp(k.machines))
	k.handleFunc("machine.exec", k.machines.HandleExec)
	k.handleFunc("machine.kill", k.machines.HandleKill)

	// Machine index handlers.
	k.handleWithSub("machine.index.head", index.KiteHandlerHead())
	k.handleWithSub("machine.index.get", index.KiteHandlerGet())

	// Vagrant
	k.handleFunc("vagrant.create", k.vagrant.Create)
	k.handleFunc("vagrant.provider", k.vagrant.Provider)
	k.handleFunc("vagrant.list", k.vagrant.List)
	k.handleFunc("vagrant.up", k.vagrant.Up)
	k.handleFunc("vagrant.halt", k.vagrant.Halt)
	k.handleFunc("vagrant.destroy", k.vagrant.Destroy)
	k.handleFunc("vagrant.status", k.vagrant.Status)
	k.handleFunc("vagrant.version", k.vagrant.Version)
	k.handleFunc("vagrant.listForwardedPorts", k.vagrant.ForwardedPorts)

	// Tunnel
	k.handleFunc("tunnel.info", k.tunnel.Info)

	// Log
	k.handleFunc("log.upload", k.uploader.Upload)

	// Docker
	// k.handleFunc("docker.create", k.docker.Create)
	// k.handleFunc("docker.connect", k.docker.Connect)
	// k.handleFunc("docker.stop", k.docker.Stop)
	// k.handleFunc("docker.start", k.docker.Start)
	// k.handleFunc("docker.remove", k.docker.RemoveContainer)
	// k.handleFunc("docker.list", k.docker.List)

	// Execution
	k.handleFunc("exec", command.Exec)

	// Terminal
	k.handleWithSub("webterm.getSessions", k.terminal.GetSessions)
	k.handleWithSub("webterm.connect", k.terminal.Connect)
	k.handleWithSub("webterm.killSession", k.terminal.KillSession)
	k.handleWithSub("webterm.killSessions", k.terminal.KillSessions)
	k.handleWithSub("webterm.rename", k.terminal.RenameSession)

	// VM -> Client methods
	ps := client.NewPubSub(k.log)
	k.handleFunc("client.Publish", ps.Publish)
	k.handleFunc("client.Subscribe", ps.Subscribe)
	k.handleFunc("client.Unsubscribe", ps.Unsubscribe)

	k.kite.OnFirstRequest(func(c *kite.Client) {
		// Koding (kloud) connects to much, don't display it.
		if c.Username != "koding" {
			k.log.Info("Kite '%s/%s/%s' is connected", c.Username, c.Environment, c.Name)
		}

		if c.Username != k.kite.Config.Username {
			return // we don't care for others
		}

		k.log.Info("Canceling disconnection timer.")
		k.collabCloser.Stop()
	})

	// Unshare collab users if the klient owner disconnects
	k.kite.OnDisconnect(func(c *kite.Client) {
		// Koding (kloud) connects to much, don't display it.
		if c.Username != "koding" {
			k.log.Info("Kite '%s/%s/%s' is disconnected", c.Username, c.Environment, c.Name)
		}

		if c.Username != k.kite.Config.Username {
			return // we don't care for others
		}

		k.log.Info("Start disconnection timer with 1 minute delay.")
		k.collabCloser.Start()
	})
}

func (k *Klient) handleFunc(pattern string, f kite.HandlerFunc) *kite.Method {
	f = metrics.WrapKiteHandler(k.metrics.Datadog, pattern, f)
	return k.kite.HandleFunc(pattern, f)
}

// handleWithSub is a middle-ware function that checks team payment status
// before invoking fn function. It will fail if team is blocked due to unpaid
// subscription.
func (k *Klient) handleWithSub(method string, fn kite.HandlerFunc) {
	k.handleFunc(method, func(r *kite.Request) (interface{}, error) {
		team, err := k.cacheTeam()
		if err != nil {
			k.log.Error("Cannot find Klient's team: %s", err)
			return nil, err
		}

		if !team.Paid {
			k.log.Error("Method %q is blocked due to unpaid subscription for %s team.", method, team.Name)
			return nil, errors.New("method is blocked")
		}

		return fn(r)
	})
}

func (k *Klient) PublicIP() (net.IP, error) {
	if k.publicIP == nil {
		ip, err := publicip.PublicIP()
		if err != nil {
			return nil, err
		}

		k.publicIP = ip
	}

	return k.publicIP, nil
}

func (k *Klient) registerURL() (u *url.URL, err error) {
	if k.config.RegisterURL != "" {
		return url.Parse(k.config.RegisterURL)
	}

	// Attempt to get the IP, and retry up to 10 times with 5 second pauses between
	// retries.
	ip, err := k.PublicIP()
	if err != nil {
		return nil, err
	}

	u = &url.URL{
		Scheme: "http",
		Host:   ip.String() + ":" + strconv.Itoa(k.config.Port),
		Path:   "/kite",
	}

	if k.kite.TLSConfig != nil {
		u.Scheme = "https"
	}

	return u, nil
}

func (k *Klient) tunnelID() string {
	if k.config.TunnelName != "" {
		return k.config.TunnelName
	}

	return konfig.Konfig.TunnelID
}

func (k *Klient) debug() bool {
	if k.config.Debug {
		return true
	}

	return konfig.Konfig.Debug
}

func (k *Klient) tunnelOptions() (*tunnel.Options, error) {
	ip, err := k.PublicIP()
	if err != nil {
		return nil, err
	}

	opts := &tunnel.Options{
		TunnelName:    k.tunnelID(),
		TunnelKiteURL: k.config.TunnelKiteURL,
		PublicIP:      ip,
		Debug:         k.config.Debug,
		Kite:          k.kite,
		NoProxy:       k.config.NoProxy,
	}

	if k.config.Port != 0 {
		opts.LocalAddr = net.JoinHostPort("127.0.0.1", strconv.Itoa(k.config.Port))
	}

	return opts, nil
}

func (k *Klient) Team() (*team.Team, error) {
	var resp stack.WhoamiResponse

	if err := k.kloud.Call("team.whoami", nil, &resp); err != nil {
		return nil, err
	}

	return resp.Team, nil
}

func (k *Klient) cacheTeam() (*team.Team, error) {
	k.teamMu.Lock()
	defer k.teamMu.Unlock()

	if k.team != nil && !k.teamUpdatedAt.IsZero() && time.Since(k.teamUpdatedAt) < time.Hour {
		return k.team, nil
	}

	team, err := k.Team()
	if err != nil {
		return nil, err
	}

	k.log.Info("Kite belongs to %q team", team.Name)

	k.team = team
	k.teamUpdatedAt = time.Now()

	return k.team, nil
}

func (k *Klient) ping() error {
	team, err := k.cacheTeam()
	if err != nil {
		return err
	}

	return k.presence.Ping(k.kite.Config.Username, team.Name)
}

// Run registers klient to Kontrol and starts the kite server. It also runs any
// necessary workers in the background.
func (k *Klient) Run() {
	go func() {
		// Delay uploading log files to give klient a chance to:
		//
		//   - write the file first-time
		//   - log essential statuses from tunnel / kontrol register
		//
		// Additionally do not block startup routine with log uploading.
		time.Sleep(k.logUploadDelay)

		for _, file := range uploader.LogFiles {
			_, err := k.uploader.UploadFile(file, k.config.LogUploadInterval)
			if err != nil && !os.IsNotExist(err) && !logrotate.IsNop(err) {
				k.log.Warning("failed to upload %q: %s", file, err)
			}
		}
	}()

	switch err := daemon.InstallScreen(); err {
	case nil:
		terminal.Reset()
	case daemon.ErrSkipInstall:
	default:
		k.log.Error("%s", err)
	}

	if k.config.ScreenTerm != "" {
		terminal.SetTerm(k.config.ScreenTerm)
	}

	// don't run the tunnel for Koding VM's, no need to check for error as we
	// are not interested in it
	isAWS, isKoding, _ := info.CheckKodingAWS()
	isManaged := konfig.Environment == "managed" || konfig.Environment == "devmanaged"

	if isManaged && isKoding {
		k.log.Error("Managed Klient is attempting to run on a Koding provided VM")
		panic(errors.New("This binary of Klient cannot run on a Koding provided VM"))
	}

	registerURL, err := k.registerURL()
	if err != nil {
		log.Fatal(err)
	}

	if (!isAWS && !isKoding && !k.config.NoTunnel) || k.tunnelID() != "" {
		opts, err := k.tunnelOptions()
		if err != nil {
			log.Fatal(err)
		}

		if err = k.tunnel.BuildOptions(opts, registerURL); err != nil {
			log.Fatal(err)
		}
	}

	if err := k.register(registerURL); err != nil {
		log.Fatal(err)
	}

	// If tunnel has successfully started, it's going to re-register
	// to Kontrol with new registerURL which will point to public
	// side of the tunnel.
	go k.tunnel.Start()

	k.log.Info("Using version: '%s' querystring: '%s'", k.config.Version, k.kite.Id)

	// TODO(rjeczalik): Enable after TMS-848.
	if k.autoupdateEnabled() {
		go k.updater.Run()
	} else {
		k.log.Warning("autoupdate is disabled")
	}

	k.kite.Run()
}

var kdPrefix = []byte("kd version")

func (k *Klient) autoupdateEnabled() bool {
	if k.config.Autoupdate {
		return true
	}

	p, err := exec.Command("kd", "-version").Output()
	if err != nil {
		return true
	}

	return !bytes.HasPrefix(bytes.TrimSpace(p), kdPrefix)
}

func (k *Klient) register(registerURL *url.URL) error {
	if u := k.tunnel.LocalKontrolURL(); u != nil {
		origURL := k.kite.Config.KontrolURL
		k.kite.Config.KontrolURL = u.String()

		k.log.Info("Register to local kontrol '%s' via the URL value: '%s'", k.kite.Config.KontrolURL, registerURL)

		_, err := k.kite.RegisterHTTP(registerURL)
		if err == nil {
			return nil
		}

		k.log.Error("Failed to register, retrying with original URL: %s", err)

		k.kite.Config.KontrolURL = origURL
	}

	k.log.Info("Register to kontrol '%s' via the URL value: '%s'", k.kite.Config.KontrolURL, registerURL)

	k.kite.RegisterHTTPForever(registerURL)

	return nil
}

func (k *Klient) Close() {
	if k.metrics != nil {
		k.metrics.Close()
	}

	k.collabCloser.Close()
	k.collab.Close()
	k.kite.Close()
}

// NewUploader creates new uploader value from the given klient configuration.
func NewUploader(kconf *KlientConfig) *uploader.Uploader {
	k := newKite(kconf)
	k.SetLogLevel(kite.ERROR)

	return uploader.New(&uploader.Options{
		KeygenURL: konfig.Konfig.Endpoints.Kloud().Public.String(),
		Kite:      k,
		Bucket:    kconf.logBucketName(),
		Region:    kconf.logBucketRegion(),
		Log:       k.Log,
	})
}

func newKite(kconf *KlientConfig) *kite.Kite {
	k := kite.NewWithConfig(kconf.Name, kconf.Version, konfig.Konfig.KiteConfig())

	if kconf.Debug {
		k.SetLogLevel(kite.DEBUG)
	}

	k.Config.Port = kconf.Port
	k.Config.Environment = kconf.Environment
	k.Config.Region = kconf.Region
	k.Id = k.Config.Id // always boot up with the same id in the kite.key

	// replace kontrolURL if's being overidden
	if kconf.KontrolURL != "" {
		k.Config.KontrolURL = kconf.KontrolURL
	}

	k.Config.VerifyAudienceFunc = verifyAudience

	if k.Config.KontrolURL == "" || k.Config.KontrolURL == "http://127.0.0.1:3000/kite" ||
		!konfig.Konfig.Endpoints.Kontrol().Equal(konfig.Builtin.Endpoints.Kontrol()) {
		k.Config.KontrolURL = konfig.Konfig.Endpoints.Kontrol().Public.String()
	}

	return k
}

// checkAuth checks whether the given incoming request is authenticated or not.
// It don't pass any request if the caller is outside of our scope.
func (k *Klient) checkAuth(r *kite.Request) (interface{}, error) {
	// only authenticated methods have correct username. For example
	// kite.ping has authentication disabled so username can be empty.
	if r.Auth == nil {
		return true, nil
	}

	// lazy return for those, no need to fetch from the DB
	if userIn(r.Username, k.kite.Config.Username, "koding") {
		return true, nil
	}

	// Allow collaboration users as well
	sharedUsers, err := k.collab.GetAll()
	if err != nil {
		return nil, fmt.Errorf("Can't read shared users from the storage. Err: %v", err)
	}

	sharedUsernames := make([]string, 0, len(sharedUsers))
	for username := range sharedUsers {
		sharedUsernames = append(sharedUsernames, username)
	}

	if !userIn(r.Username, sharedUsernames...) {
		return nil, fmt.Errorf("User '%s' is not allowed to make a call to us.", r.Username)
	}

	return true, nil
}

func (k *Klient) updateKiteKey(reg *kiteproto.RegisterResult) {
	if reg.KiteKey == "" {
		return
	}

	if err := k.writeKiteKey(reg.KiteKey); err != nil {
		k.kite.Log.Warning("kite.key update failed: %s", err)
	}
}

func (k *Klient) writeKiteKey(content string) error {
	konfig, err := configstore.Used()
	if err != nil {
		return err
	}

	konfig.KiteKey = strings.TrimSpace(content)

	return configstore.Use(konfig)
}

func openBoltDB(opts *cfg.CacheOptions) (*bolt.DB, error) {
	return bolt.Open(opts.File, 0644, opts.BoltDB)
}

// userIn checks whether the given user exists in the users list or not. It
// returns true if the user exists.
func userIn(user string, users ...string) bool {
	for _, u := range users {
		if u == user {
			return true
		}
	}
	return false
}

// TODO(rjeczalik): Remove managed/devmanaged channels
// and remove custom verifyAudience function.
var (
	prodEnvs = map[string]struct{}{
		"managed":    {},
		"production": {},
	}
	devEnvs = map[string]struct{}{
		"devmanaged":  {},
		"development": {},
	}
	kiteNames = map[string]struct{}{
		"kd":     {},
		"klient": {},
	}
)

func match(allowed map[string]struct{}, values ...string) bool {
	for _, v := range values {
		if _, ok := allowed[v]; !ok {
			return false
		}
	}

	return true
}

func verifyAudience(kite *kiteproto.Kite, audience string) error {
	switch audience {
	case "/":
		// The root audience is like superuser - it has access to everything.
		return nil
	case "":
		return errors.New("invalid empty audience")
	}

	aud, err := kiteproto.KiteFromString(audience)
	if err != nil {
		return fmt.Errorf("invalid audience: %s (%s)", err, audience)
	}

	if kite.Username != aud.Username {
		return fmt.Errorf("audience: username %q not allowed (%s)", aud.Username, audience)
	}

	// Verify environment - managed environment means production klient
	// running on a user's laptop; devmanaged is for development/sandobx
	// environments.
	//
	// TODO(rjeczalik): klient should always have development/production
	// values for the environment fields - the managed flag should be
	// set elsewhere; it'd also make the deployment process easier
	// (2 delivery channels instead of 4).
	switch {
	case aud.Environment == "":
		// ok - empty matches all
	case kite.Environment == aud.Environment:
		// ok - environment matches
	case match(prodEnvs, kite.Environment, aud.Environment):
		// ok - either remote or local is managed kite from development channel
	case match(devEnvs, kite.Environment, aud.Environment):
		// ok - either remote or local is managed kite from development channel
	default:
		return fmt.Errorf("audience: environment %q not allowed (%s)", aud.Environment, audience)
	}

	switch {
	case aud.Name == "":
		// ok - empty matches all
	case kite.Name == aud.Name:
	case match(kiteNames, kite.Name, aud.Name):
	default:
		return fmt.Errorf("audience: kite %q not allowed (%s)", aud.Name, audience)
	}

	return nil
}
