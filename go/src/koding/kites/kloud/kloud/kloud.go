package kloud

import (
	"koding/db/mongodb"
	"koding/kites/kloud/digitalocean"
	"koding/kites/kloud/idlock"
	"koding/kodingkite"
	"koding/tools/config"
	"log"
	"os"

	"github.com/koding/logging"
)

const (
	VERSION = "0.0.1"
	NAME    = "kloud"
)

var (
	defaultSnapshotName = "koding-klient-0.0.1"
	providers           = make(map[string]Provider)
)

type Kloud struct {
	Config *config.Config
	Log    logging.Logger

	Storage Storage

	idlock *idlock.IdLock

	Name    string
	Version string
	Region  string
	Port    int

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

	if k.Log == nil {
		k.Log = createLogger(NAME, k.Debug)
	}

	if k.Storage == nil {
		k.Storage = &MongoDB{session: mongodb.NewMongoDB(k.Config.Mongo)}
	}

	kt, err := kodingkite.New(k.Config, k.Name, k.Version)
	if err != nil {
		log.Fatalln(err)
	}

	kt.Config.Region = k.Region
	kt.Config.Port = k.Port

	kt.HandleFunc("build", k.build)
	kt.HandleFunc("start", k.start)
	kt.HandleFunc("stop", k.stop)
	kt.HandleFunc("restart", k.restart)
	kt.HandleFunc("destroy", k.destroy)
	kt.HandleFunc("info", k.info)

	k.InitializeProviders()

	return kt
}

func (k *Kloud) InitializeProviders() {
	providers = map[string]Provider{
		"digitalocean": &digitalocean.DigitalOcean{
			Log: createLogger("digitalocean", k.Debug),
		},
	}
}

func createLogger(name string, debug bool) logging.Logger {
	log := logging.NewLogger(name)
	logHandler := logging.NewWriterHandler(os.Stderr)
	logHandler.Colorize = true
	log.SetHandler(logHandler)

	if debug {
		log.SetLevel(logging.DEBUG)
		logHandler.SetLevel(logging.DEBUG)
	}

	return log
}
