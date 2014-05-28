package kloud

import (
	"koding/kites/kloud/digitalocean"
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

type Kloud struct {
	Config            *config.Config
	Name              string
	Version           string
	Region            string
	Port              int
	KontrolPublicKey  string
	KontrolPrivateKey string
	KontrolURL        string

	Log   logging.Logger
	Debug bool
}

func (k *Kloud) NewKloud() *kodingkite.KodingKite {
	k.Name = NAME
	k.Version = VERSION
	k.Log = createLogger(NAME, k.Debug)

	kt, err := kodingkite.New(k.Config, k.Name, k.Version)
	if err != nil {
		log.Fatalln(err)
	}

	kt.Config.Region = k.Region
	kt.Config.Port = k.Port

	kt.HandleFunc("build", k.build)
	kt.HandleFunc("start", start)
	kt.HandleFunc("stop", stop)
	kt.HandleFunc("restart", restart)
	kt.HandleFunc("destroy", destroy)
	kt.HandleFunc("info", info)

	k.InitializeProviders()

	return kt
}

func (k *Kloud) InitializeProviders() {
	providers = map[string]interface{}{
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
