package app

import (
	"errors"
	"fmt"
	"log"
	"net"
	"net/http"
	"net/http/cookiejar"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"sync"
	"time"

	"koding/klient/client"
	"koding/klient/collaboration"
	"koding/klient/command"
	"koding/klient/control"
	"koding/klient/fix"
	"koding/klient/fs"
	"koding/klient/gatherrun"
	"koding/klient/info"
	"koding/klient/info/publicip"
	"koding/klient/logfetcher"
	"koding/klient/protocol"
	"koding/klient/remote"
	"koding/klient/remote/mount"
	"koding/klient/sshkeys"
	"koding/klient/storage"
	"koding/klient/terminal"
	"koding/klient/tunnel"
	"koding/klient/usage"
	"koding/klient/vagrant"

	"github.com/boltdb/bolt"
	"github.com/koding/kite"
	"github.com/koding/kite/config"
	"github.com/koding/kite/sockjsclient"
)

const (
	// The default timeout to use for Klient's http.Client
	defaultXHRTimeout = 30 * time.Second
)

var (
	// we also could use an atomic boolean this is simple for now.
	updating   = false
	updatingMu sync.Mutex // protects updating

	// the implementation of New() doesn't have any error to be returned yet it
	// returns, so it's totally safe to neglect the error
	cookieJar, _ = cookiejar.New(nil)
)

// Klient is the central app which provides all available methods.
type Klient struct {
	// kite defines the server running and powering Klient.
	kite *kite.Kite

	// collab is used to store authorized third party users and allows them to
	// use the available methods. It provides methods to add or remove users
	// from the storage
	collab *collaboration.Collaboration

	storage *storage.Storage

	// terminal provides wmethods
	terminal *terminal.Terminal

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

	log kite.Logger

	// disconnectTimer is used track disconnected users and eventually remove
	// them from the collaboration storage.
	disconnectTimer *time.Timer

	// config stores all necessary configuration needed for Klient to work.
	// It's supplied with the NewKlient() function.
	config *KlientConfig

	// remote handles persistence of remote related options, including
	// mounting folders, listing remote machines that this Klient is
	// connected to, and so on. It is typically called from a local kite,
	// and is responsible for Klient's `remote.*` methods.
	remote *remote.Remote

	// updater polls s3://latest-version.txt with config.UpdateInterval
	// and updates current binary if version is never than config.Version.
	updater *Updater

	// publicIP is a cached public IP address of the klient.
	publicIP net.IP
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
	DBPath       string

	UpdateInterval time.Duration
	UpdateURL      string

	VagrantHome string

	TunnelName    string
	TunnelKiteURL string

	NoTunnel bool
	NoProxy  bool

	LogBucketRegion   string
	LogBucketName     string
	LogUploadLimit    int
	LogUploadInterval time.Duration
}

// NewKlient returns a new Klient instance
func NewKlient(conf *KlientConfig) *Klient {
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
		// "docker.create":       true,
		// "docker.connect":      true,
		// "docker.stop":         true,
		// "docker.start":        true,
		// "docker.remove":       true,
		// "docker.list":         true,
	})

	k := newKite(conf)
	term := terminal.New(k.Log, conf.ScreenrcPath)
	term.InputHook = usg.Reset

	db, err := openBoltDb(conf.DBPath)
	if err != nil {
		k.Log.Warning("Couldn't open BoltDB: %s", err)
	}

	vagrantOpts := &vagrant.Options{
		Home:  conf.VagrantHome,
		DB:    db, // nil is ok, fallbacks to in-memory storage
		Log:   k.Log,
		Debug: conf.Debug,
	}

	// use websocket connection for tunnelserver
	tunCfg := k.Config.Copy()
	tunCfg.Transport = config.WebSocket

	tunOpts := &tunnel.Options{
		DB:      db,
		Log:     k.Log,
		Config:  tunCfg,
		NoProxy: conf.NoProxy,
	}

	t, err := tunnel.New(tunOpts)
	if err != nil {
		log.Fatal(err)
	}

	if conf.UpdateInterval < time.Minute {
		k.Log.Warning("Update interval can't be less than one minute. Setting to one minute.")
		conf.UpdateInterval = time.Minute
	}

	mountEvents := make(chan *mount.Event)

	remoteOpts := &remote.RemoteOptions{
		Kite:     k,
		Log:      k.Log,
		Storage:  storage.New(db),
		EventSub: mountEvents,
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
		remote:   remote.NewRemote(remoteOpts),
		updater: &Updater{
			Endpoint:       conf.UpdateURL,
			Interval:       conf.UpdateInterval,
			CurrentVersion: conf.Version,
			MountEvents:    mountEvents,
			Log:            k.Log,
		},
	}

	// This is important, don't forget it
	kl.RegisterMethods()

	return kl
}

// An implementation of the kite xhr dialer that uses a set http timeout,
// and not the zero timeout value that kite.Dial() will pass to DialOptions.
//
// https://github.com/koding/kite/blob/master/sockjsclient/xhr.go#L28
func klientXHRClientFunc(opts *sockjsclient.DialOptions) *http.Client {
	if opts.Timeout == 0 {
		opts.Timeout = defaultXHRTimeout
	}

	return &http.Client{
		Timeout: opts.Timeout,
		Jar:     cookieJar,
	}
}

// Kite retursn the underlying Kite instance
func (k *Klient) Kite() *kite.Kite {
	return k.kite
}

// RegisterMethods registers all public available methods
func (k *Klient) RegisterMethods() {
	// don't allow anyone to call a method if we are during an update.
	k.kite.PreHandleFunc(func(r *kite.Request) (interface{}, error) {
		// Koding (kloud) connects to much, don't display it.
		if r.Username != "koding" {
			k.log.Info("Kite '%s/%s/%s' called method: '%s'",
				r.Username, r.Client.Environment, r.Client.Name, r.Method)
		}

		k.updater.Wait.Wait()

		return true, nil
	})

	k.kite.PreHandleFunc(k.checkAuth)

	// Metrics, is used by Kloud to get usage so Kloud can stop free VMs
	k.kite.PreHandleFunc(k.usage.Counter) // we measure every incoming request
	k.kite.HandleFunc("klient.usage", k.usage.Current)

	// Klient Info method(s)
	k.kite.HandleFunc("klient.info", info.Info)

	// Collaboration, is used by our Koding.com browser client.
	k.kite.HandleFunc("klient.disable", control.Disable)
	k.kite.HandleFunc("klient.share", k.collab.Share)
	k.kite.HandleFunc("klient.unshare", k.collab.Unshare)
	k.kite.HandleFunc("klient.shared", k.collab.Shared)

	// Adds the remote.* methods, depending on OS.
	k.addRemoteHandlers()

	// SSH keys
	k.kite.HandleFunc("sshkeys.list", sshkeys.List)
	k.kite.HandleFunc("sshkeys.add", sshkeys.Add)
	k.kite.HandleFunc("sshkeys.delete", sshkeys.Delete)

	// Storage
	k.kite.HandleFunc("storage.set", k.storage.SetValue)
	k.kite.HandleFunc("storage.get", k.storage.GetValue)
	k.kite.HandleFunc("storage.delete", k.storage.DeleteValue)

	// Logfetcher
	k.kite.HandleFunc("log.tail", logfetcher.Tail)

	// Filesystem
	k.kite.HandleFunc("fs.readDirectory", fs.ReadDirectory)
	k.kite.HandleFunc("fs.glob", fs.Glob)
	k.kite.HandleFunc("fs.readFile", fs.ReadFile)
	k.kite.HandleFunc("fs.writeFile", fs.WriteFile)
	k.kite.HandleFunc("fs.uniquePath", fs.UniquePath)
	k.kite.HandleFunc("fs.getInfo", fs.GetInfo)
	k.kite.HandleFunc("fs.setPermissions", fs.SetPermissions)
	k.kite.HandleFunc("fs.remove", fs.Remove)
	k.kite.HandleFunc("fs.rename", fs.Rename)
	k.kite.HandleFunc("fs.createDirectory", fs.CreateDirectory)
	k.kite.HandleFunc("fs.move", fs.Move)
	k.kite.HandleFunc("fs.copy", fs.Copy)
	k.kite.HandleFunc("fs.getDiskInfo", fs.GetDiskInfo)

	// Vagrant
	k.kite.HandleFunc("vagrant.create", k.vagrant.Create)
	k.kite.HandleFunc("vagrant.provider", k.vagrant.Provider)
	k.kite.HandleFunc("vagrant.list", k.vagrant.List)
	k.kite.HandleFunc("vagrant.up", k.vagrant.Up)
	k.kite.HandleFunc("vagrant.halt", k.vagrant.Halt)
	k.kite.HandleFunc("vagrant.destroy", k.vagrant.Destroy)
	k.kite.HandleFunc("vagrant.status", k.vagrant.Status)
	k.kite.HandleFunc("vagrant.version", k.vagrant.Version)
	k.kite.HandleFunc("vagrant.listForwardedPorts", k.vagrant.ForwardedPorts)

	// Tunnel
	k.kite.HandleFunc("tunnel.info", k.tunnel.Info)

	// Docker
	// k.kite.HandleFunc("docker.create", k.docker.Create)
	// k.kite.HandleFunc("docker.connect", k.docker.Connect)
	// k.kite.HandleFunc("docker.stop", k.docker.Stop)
	// k.kite.HandleFunc("docker.start", k.docker.Start)
	// k.kite.HandleFunc("docker.remove", k.docker.RemoveContainer)
	// k.kite.HandleFunc("docker.list", k.docker.List)

	// Execution
	k.kite.HandleFunc("exec", command.Exec)

	// Terminal
	k.kite.HandleFunc("webterm.getSessions", k.terminal.GetSessions)
	k.kite.HandleFunc("webterm.connect", k.terminal.Connect)
	k.kite.HandleFunc("webterm.killSession", k.terminal.KillSession)
	k.kite.HandleFunc("webterm.killSessions", k.terminal.KillSessions)
	k.kite.HandleFunc("webterm.rename", k.terminal.RenameSession)

	// VM -> Client methods
	ps := client.NewPubSub(k.log)
	k.kite.HandleFunc("client.Publish", ps.Publish)
	k.kite.HandleFunc("client.Subscribe", ps.Subscribe)
	k.kite.HandleFunc("client.Unsubscribe", ps.Unsubscribe)

	k.kite.OnFirstRequest(func(c *kite.Client) {
		// Koding (kloud) connects to much, don't display it.
		if c.Username != "koding" {
			k.log.Info("Kite '%s/%s/%s' is connected", c.Username, c.Environment, c.Name)
		}

		if c.Username != k.kite.Config.Username {
			return // we don't care for others
		}

		// it's still not initialized, so don't do anything
		if k.disconnectTimer != nil {
			// stop previously started disconnect timer.
			k.log.Info("Disconnection timer is cancelled.")
			k.disconnectTimer.Stop()
		}

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

		// if there is any previously created timers stop them so we don't leak
		// goroutines
		if k.disconnectTimer != nil {
			k.disconnectTimer.Stop()
		}

		k.log.Info("Disconnection timer of 1 minutes is fired.")
		k.disconnectTimer = time.NewTimer(time.Minute * 1)

		// Close all active sessions of the current. Do not close it
		// immediately, instead of give some time so users can safely exit. If
		// the user reconnects again the timer will be stopped so we don't
		// unshare for network hiccups accidentally.
		go func() {
			select {
			case <-k.disconnectTimer.C:
				sharedUsers, err := k.collab.GetAll()
				if err != nil {
					k.log.Warning("Couldn't unshare users: '%s'", err)
					return
				}

				if len(sharedUsers) == 0 {
					return // nothing to do ...
				}

				k.log.Info("Unsharing users '%s'", sharedUsers)
				for user, option := range sharedUsers {
					// dont touch permanent users
					if option.Permanent {
						k.log.Info("User is permanent, avoiding it: '%s'", user)
						continue
					}

					if err := k.collab.Delete(user); err != nil {
						k.log.Warning("Couldn't delete user from storage: '%s'", err)
					}
					k.terminal.CloseSessions(user)
				}
			}
		}()
	})
}

func (k *Klient) PublicIP() (net.IP, error) {
	if k.publicIP == nil {
		ip, err := publicip.PublicIPRetry(10, 5*time.Second, k.log)
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

func (k *Klient) tunnelOptions() (*tunnel.Options, error) {
	ip, err := k.PublicIP()
	if err != nil {
		return nil, err
	}

	opts := &tunnel.Options{
		TunnelName:    k.config.TunnelName,
		TunnelKiteURL: k.config.TunnelKiteURL,
		PublicIP:      ip,
		Debug:         k.config.Debug,
		Config:        k.kite.Config.Copy(),
		NoProxy:       k.config.NoProxy,
	}

	if k.config.Port != 0 {
		opts.LocalAddr = net.JoinHostPort("127.0.0.1", strconv.Itoa(k.config.Port))
	}

	return opts, nil
}

// Run registers klient to Kontrol and starts the kite server. It also runs any
// necessary workers in the background.
func (k *Klient) Run() {
	// don't run the tunnel for Koding VM's, no need to check for error as we
	// are not interested in it
	isKoding, _ := info.CheckKoding()

	if (protocol.Environment == "managed" || protocol.Environment == "devmanaged") && isKoding {
		k.log.Error("Managed Klient is attempting to run on a Koding provided VM")
		panic(errors.New("This binary of Klient cannot run on a Koding provided VM"))
	}

	registerURL, err := k.registerURL()
	if err != nil {
		log.Fatal(err)
	}

	if !isKoding && !k.config.NoTunnel {
		opts, err := k.tunnelOptions()
		if err != nil {
			log.Fatal(err)
		}

		// If tunnel has started, the returned url overwrites registerURL
		// pointing at public end of the tunnel. Otherwise it's a nop
		// and returns registerURL.
		registerURL, err = k.tunnel.Start(opts, registerURL)
		if err != nil {
			log.Fatal(err)
		}
	}

	if err := k.register(registerURL); err != nil {
		log.Fatal(err)
	}

	if isKoding {
		go gatherrun.Run(k.config.Environment, k.kite.Config.Username)
		go func() {
			if err := fix.Run(k.kite.Config.Username); err != nil {
				k.log.Error("Couldn't replace key %s", err)
			}
		}()
	}

	// Initializing the remote re-establishes any previously-running remote
	// connections, such as mounted folders. This needs to be run *after*
	// Klient is setup and running, to get a valid connection to Kontrol.
	go k.initRemote()

	k.log.Info("Using version: '%s' querystring: '%s'", k.config.Version, k.kite.Id)

	go k.updater.Run()

	k.kite.Run()
}

func (k *Klient) register(registerURL *url.URL) error {
	// replace kontrolURL if's being overidden
	if k.config.KontrolURL != "" {
		k.kite.Config.KontrolURL = k.config.KontrolURL
	}

	k.log.Info("Register to kontrol '%s' via the URL value: '%s'", k.kite.Config.KontrolURL, registerURL)

	k.kite.RegisterHTTPForever(registerURL)

	return nil
}

func (k *Klient) Close() {
	k.collab.Close()
	k.kite.Close()
}

func newKite(kconf *KlientConfig) *kite.Kite {
	k := kite.New(kconf.Name, kconf.Version)

	if kconf.Debug {
		k.SetLogLevel(kite.DEBUG)
	}

	conf := config.MustGet()
	k.Config = conf
	k.Config.Port = kconf.Port
	k.Config.Environment = kconf.Environment
	k.Config.Region = kconf.Region
	k.Id = conf.Id // always boot up with the same id in the kite.key
	// Set klient to use XHR Polling, since Prod Koding only supports XHR
	k.Config.Transport = config.XHRPolling
	k.ClientFunc = klientXHRClientFunc
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
	if userIn(r.Username, []string{k.kite.Config.Username, "koding"}...) {
		return true, nil
	}

	// Allow collaboration users as well
	sharedUsers, err := k.collab.GetAll()
	if err != nil {
		return nil, fmt.Errorf("Can't read shared users from the storage. Err: %v", err)
	}

	sharedUsernames := make([]string, 0)
	for username := range sharedUsers {
		sharedUsernames = append(sharedUsernames, username)
	}

	if !userIn(r.Username, sharedUsernames...) {
		return nil, fmt.Errorf("User '%s' is not allowed to make a call to us.", r.Username)
	}

	return true, nil
}

func openBoltDb(dbpath string) (*bolt.DB, error) {
	if dbpath == "" {
		return nil, errors.New("DB path is empty")
	}

	// create if it doesn't exists
	if err := os.MkdirAll(filepath.Dir(dbpath), 0755); err != nil {
		return nil, err
	}

	return bolt.Open(dbpath, 0644, &bolt.Options{Timeout: 5 * time.Second})
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
