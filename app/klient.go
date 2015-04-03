package app

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/boltdb/bolt"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite/config"
	"github.com/koding/klient/collaboration"
	"github.com/koding/klient/command"
	"github.com/koding/klient/fs"
	"github.com/koding/klient/sshkeys"
	"github.com/koding/klient/storage"
	"github.com/koding/klient/terminal"
	"github.com/koding/klient/usage"
)

var (
	// we also could use an atomic boolean this is simple for now.
	updating   = false
	updatingMu sync.Mutex // protects updating
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

	// docker provides the docker related methods.
	// docker *docker.Docker

	// usage counts and tracks all called metrics. It also provides a method
	// that return those informations
	usage *usage.Usage

	log kite.Logger

	// disconnectTimer is used track disconnected users and eventually remove
	// them from the collaboration storage.
	disconnectTimer *time.Timer

	// config stores all necessary configuration needed for Klient to work.
	// It's supplied with the NewKlient() function.
	config *KlientConfig
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

	kl := &Klient{
		kite:    k,
		collab:  collaboration.New(db), // nil is ok, fallbacks to in memory storage
		storage: storage.New(db),       // nil is ok, fallbacks to in memory storage
		// docker:   docker.New("unix://var/run/docker.sock", k.Log),
		terminal: term,
		usage:    usg,
		log:      k.Log,
		config:   conf,
	}

	// This is important, don't forget it
	kl.RegisterMethods()

	return kl
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

		updatingMu.Lock()
		defer updatingMu.Unlock()

		if updating {
			return nil, errors.New("Updating klient. Can't accept any method.")
		}

		return true, nil
	})

	k.kite.PreHandleFunc(k.checkAuth)

	// Metrics, is used by Kloud to get usage so Kloud can stop free VMs
	k.kite.PreHandleFunc(k.usage.Counter) // we measure every incoming request
	k.kite.HandleFunc("klient.usage", k.usage.Current)

	// Collaboration, is used by our Koding.com browser client.
	k.kite.HandleFunc("klient.share", k.collab.Share)
	k.kite.HandleFunc("klient.unshare", k.collab.Unshare)
	k.kite.HandleFunc("klient.shared", k.collab.Shared)

	// SSH keys
	k.kite.HandleFunc("sshkeys.List", sshkeys.List)
	k.kite.HandleFunc("sshkeys.Add", sshkeys.Add)
	k.kite.HandleFunc("sshkeys.Delete", sshkeys.Delete)

	// Storage
	k.kite.HandleFunc("storage.Set", k.storage.SetValue)
	k.kite.HandleFunc("storage.Get", k.storage.GetValue)
	k.kite.HandleFunc("storage.Delete", k.storage.DeleteValue)

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

// Run registers klient to Kontrol and starts the kite server. It also runs any
// necessary workers in the background.
func (k *Klient) Run() {
	k.startUpdater()

	if err := k.register(); err != nil {
		panic(err)
	}

	k.kite.Run()
}

func (k *Klient) startUpdater() {
	if k.config.UpdateInterval < time.Minute {
		k.log.Warning("Update interval can't be less than one minute. Setting to one minute.")
		k.config.UpdateInterval = time.Minute
	}

	// start our updater in the background
	updater := &Updater{
		Endpoint:       k.config.UpdateURL,
		Interval:       k.config.UpdateInterval,
		CurrentVersion: k.config.Version,
		Log:            k.log,
	}
	go updater.Run()
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
