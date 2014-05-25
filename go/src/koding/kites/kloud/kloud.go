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

	// Koding config, will be initialized in main
	conf *config.Config

	// Kontrol related variables to generate tokens
	publicKey  string
	privateKey string
	kontrolURL string
)

func main() {
	flag.Parse()
	if *flagProfile == "" || *flagRegion == "" {
		log.Fatal("Please specify profile via -c and region via -r. Aborting.")
	}

	if *flagVersion {
		fmt.Println(VERSION)
		os.Exit(0)
	}

	conf = config.MustConfig(*flagProfile)

	u, err := url.Parse(*flagKontrolURL)
	if err != nil {
		log.Fatalln(err)
	}
	kontrolURL = u.String()

	publicKey = *flagPublicKey
	if *flagPublicKey == "" {
		pubKey, err := ioutil.ReadFile(conf.NewKontrol.PublicKeyFile)
		if err != nil {
			log.Fatalln(err)
		}
		publicKey = string(pubKey)
	}

	privateKey = *flagPrivateKey
	if *flagPrivateKey == "" {
		privKey, err := ioutil.ReadFile(conf.NewKontrol.PrivateKeyFile)
		if err != nil {
			log.Fatalln(err)
		}
		privateKey = string(privKey)
	}

	k, err := kodingkite.New(conf, NAME, VERSION)
	if err != nil {
		log.Fatalln(err)
	}

	k.Config.Region = *flagRegion
	k.Config.Port = *flagPort

	k.HandleFunc("build", build)
	k.HandleFunc("start", start)
	k.HandleFunc("stop", stop)
	k.HandleFunc("restart", restart)
	k.HandleFunc("destroy", destroy)
	k.HandleFunc("info", info)

	k.Run()
}
