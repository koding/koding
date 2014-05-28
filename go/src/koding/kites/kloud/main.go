package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"koding/kites/kloud/kloud"
	"koding/tools/config"
	"log"
	"net/url"
	"os"

	"github.com/koding/logging"
)

var (
	flagIP         = flag.String("ip", "", "Change public ip")
	flagPort       = flag.Int("port", 3000, "Change running port")
	flagVersion    = flag.Bool("version", false, "Show version and exit")
	flagDebug      = flag.Bool("debug", false, "Enable debug mode")
	flagRegion     = flag.String("r", "", "Change region")
	flagProfile    = flag.String("c", "", "Configuration profile from file")
	flagKontrolURL = flag.String("kontrol-url", "", "Kontrol URL to be connected")
	flagPublicKey  = flag.String("public-key", "", "Public RSA key of Kontrol")
	flagPrivateKey = flag.String("private-key", "", "Private RSA key of Kontrol")
)

func main() {
	flag.Parse()
	if *flagProfile == "" || *flagRegion == "" {
		log.Fatal("Please specify profile via -c and region via -r. Aborting.")
	}

	if *flagVersion {
		fmt.Println(kloud.VERSION)
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

	k := &kloud.Kloud{
		Region:            *flagRegion,
		Port:              *flagPort,
		Log:               createLogger(kloud.NAME, *flagDebug),
		Config:            conf,
		KontrolURL:        kontrolURL,
		KontrolPrivateKey: privateKey,
		KontrolPublicKey:  publicKey,
	}

	k.NewKloud().Run()
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
