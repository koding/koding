package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"koding/kodingkite"
	"koding/tools/config"
	"log"
	"net/url"
	"os"
)

const (
	VERSION = "0.0.1"
	NAME    = "kloud"
)

var (
	flagIP         = flag.String("ip", "", "Change public ip")
	flagPort       = flag.Int("port", 3000, "Change running port")
	flagVersion    = flag.Bool("version", false, "Show version and exit")
	flagRegion     = flag.String("r", "", "Change region")
	flagProfile    = flag.String("c", "", "Configuration profile from file")
	flagKontrolURL = flag.String("kontrol-url", "", "Kontrol URL to be connected")
	flagPublicKey  = flag.String("public-key", "", "Public RSA key of Kontrol")
	flagPrivateKey = flag.String("private-key", "", "Private RSA key of Kontrol")
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

func main() {
	flag.Parse()
	if *flagProfile == "" || *flagRegion == "" {
		log.Fatal("Please specify profile via -c and region via -r. Aborting.")
	}

	if *flagVersion {
		fmt.Println(VERSION)
		os.Exit(0)
	}

	conf := config.MustConfig(*flagProfile)

	u, err := url.Parse(*flagKontrolURL)
	if err != nil {
		log.Fatalln(err)
	}
	kontrolURL := u.String()

	publicKey := *flagPublicKey
	if *flagPublicKey == "" {
		pubKey, err := ioutil.ReadFile(conf.NewKontrol.PublicKeyFile)
		if err != nil {
			log.Fatalln(err)
		}
		publicKey = string(pubKey)
	}

	privateKey := *flagPrivateKey
	if *flagPrivateKey == "" {
		privKey, err := ioutil.ReadFile(conf.NewKontrol.PrivateKeyFile)
		if err != nil {
			log.Fatalln(err)
		}
		privateKey = string(privKey)
	}

	kloud := &Kloud{
		Name:              NAME,
		Version:           VERSION,
		Region:            *flagRegion,
		Port:              *flagPort,
		Config:            conf,
		KontrolURL:        kontrolURL,
		KontrolPrivateKey: privateKey,
		KontrolPublicKey:  publicKey,
	}

	kloud.NewKloud().Run()
}

func (k *Kloud) NewKloud() *kodingkite.KodingKite {
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
