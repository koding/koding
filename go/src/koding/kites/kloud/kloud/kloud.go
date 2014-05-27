package kloud

import (
	"koding/kodingkite"
	"koding/tools/config"
	"log"
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

	return kt
}
