package kloud

import (
	"fmt"
	"io/ioutil"
	"koding/db/mongodb"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/idlock"
	"koding/kites/kloud/kloud/protocol"
	"koding/kites/kloud/provider/digitalocean"
	"koding/kites/kloud/provider/openstack"
	"koding/kodingkite"
	"koding/tools/config"
	"log"
	"os"

	"github.com/koding/kite"
	"github.com/koding/logging"
	"github.com/koding/redis"
)

const (
	VERSION = "0.0.1"
	NAME    = "kloud"
)

var (
	providers = make(map[string]protocol.Provider)
)

type Kloud struct {
	Config *config.Config
	Log    logging.Logger
	Kite   *kite.Kite

	Storage  Storage
	Eventers map[string]eventer.Eventer

	idlock *idlock.IdLock

	Name    string
	Version string
	Region  string
	Port    int

	// Used to uniquely identifiy kloud instances
	UniqueId string

	// needed for signing/generating kite tokens
	KontrolPublicKey  string
	KontrolPrivateKey string
	KontrolURL        string

	Debug bool
}

func (k *Kloud) NewKloud() *kodingkite.KodingKite {
	if k.Config == nil {
		panic("config is not initialized")
	}

	k.Name = NAME
	k.Version = VERSION

	k.idlock = idlock.New()

	kt, err := kodingkite.New(k.Config, k.Name, k.Version)
	if err != nil {
		log.Fatalln(err)
	}
	k.Kite = kt.Kite

	k.Log = createLogger(NAME, k.Debug)

	if k.UniqueId == "" {
		k.UniqueId = uniqueId()
	}

	if k.Storage == nil {
		mongodbSession := &MongoDB{
			session:  mongodb.NewMongoDB(k.Config.Mongo),
			assignee: k.UniqueId,
			log:      k.Log,
		}

		if err := mongodbSession.CleanupOldData(); err != nil {
			k.Log.Notice("Cleaning up mongodb err: %s", err.Error())
		}

		k.Storage = mongodbSession
	}

	if k.Eventers == nil {
		k.Eventers = make(map[string]eventer.Eventer)
	}

	kt.Config.Region = k.Region
	kt.Config.Port = k.Port

	k.ControlFunc("build", k.build)
	k.ControlFunc("start", k.start)
	k.ControlFunc("stop", k.stop)
	k.ControlFunc("restart", k.restart)
	k.ControlFunc("destroy", k.destroy)
	k.ControlFunc("info", k.info)
	kt.HandleFunc("event", k.event)

	k.InitializeProviders()

	return kt
}

func (k *Kloud) SignFunc(username string) (string, string, error) {
	k.Log.Debug("Signing a key for user: '%s' kontrolURL: %s ", username, k.KontrolURL)
	return createKey(username, k.KontrolURL, k.KontrolPrivateKey, k.KontrolPublicKey)
}

func (k *Kloud) GetProvider(providerName string) (protocol.Provider, error) {
	provider, ok := providers[providerName]
	if !ok {
		return nil, NewError(ErrProviderNotFound)
	}

	return provider, nil
}

func (k *Kloud) InitializeProviders() {
	r := redis.MustRedisSession(&redis.RedisConf{Server: k.Config.Redis})
	prefix := fmt.Sprintf("%s:%s", NAME, k.Kite.Config.Environment)
	r.SetPrefix(prefix)

	// Our digitalocean api uses lots of logs, the only way to supress them is
	// to disable std log package.
	log.SetOutput(ioutil.Discard)

	providers = map[string]protocol.Provider{
		"digitalocean": &digitalocean.Provider{
			Log:         createLogger("digitalocean", k.Debug),
			SignFunc:    k.SignFunc,
			Redis:       r,
			Region:      k.Region,
			Environment: k.Config.Environment,
		},
		"rackspace": &openstack.Provider{
			Log:          createLogger("rackspace", k.Debug),
			SignFunc:     k.SignFunc,
			Region:       k.Region,
			Environment:  k.Config.Environment,
			AuthURL:      "rackspace-us", // defaults to: https://identity.api.rackspacecloud.com/v2.0"
			ProviderName: "rackspace",
		},
	}
}

func uniqueId() string {
	// TODO: add a unique identifier, for letting multiple version of the same
	// worker work on the same hostname.
	hostname, err := os.Hostname()
	if err != nil {
		panic(err) // we should not let it start
	}

	return fmt.Sprintf("%s-%s", NAME, hostname)
}

func createLogger(name string, debug bool) logging.Logger {
	handlers := make([]logging.Handler, 0)

	log := logging.NewLogger(name)
	writerHandler := logging.NewWriterHandler(os.Stderr)
	writerHandler.Colorize = true

	if debug {
		log.SetLevel(logging.DEBUG)
		writerHandler.SetLevel(logging.DEBUG)
	}

	handlers = append(handlers, writerHandler)

	logPath := "/var/log/koding/" + name + ".log"
	logFile, err := os.Create(logPath)
	if err != nil {
		log.Warning("Can't open log file: %s", err)
	} else {
		fileHandler := logging.NewWriterHandler(logFile)
		fileHandler.Colorize = false

		if debug {
			fileHandler.SetLevel(logging.DEBUG)
		}

		handlers = append(handlers, fileHandler)
	}

	log.SetHandler(logging.NewMultiHandler(handlers...))
	return log
}
