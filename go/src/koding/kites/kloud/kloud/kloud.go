package kloud

import (
	"koding/kites/kloud/digitalocean"
	"koding/kodingkite"
	"koding/tools/config"
	"log"

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
	Log               logging.Logger
}

func (k *Kloud) NewKloud() *kodingkite.KodingKite {
	k.Name = NAME
	k.Version = VERSION

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
		"digitalocean": &digitalocean.DigitalOcean{},
	}
}
