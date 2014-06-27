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
)

var (
	flagIP         = flag.String("ip", "", "Change public ip")
	flagPort       = flag.Int("port", 3000, "Change running port")
	flagVersion    = flag.Bool("version", false, "Show version and exit")
	flagDebug      = flag.Bool("debug", false, "Enable debug mode")
	flagProdMode   = flag.Bool("prod", false, "Enable production mode")
	flagRegion     = flag.String("r", "", "Change region")
	flagProfile    = flag.String("c", "", "Configuration profile from file")
	flagKontrolURL = flag.String("kontrol-url", "", "Kontrol URL to be connected")
	flagPublicKey  = flag.String("public-key", "", "Public RSA key of Kontrol")
	flagPrivateKey = flag.String("private-key", "", "Private RSA key of Kontrol")
	flagUniqueId   = flag.String("id", "", "Start kloud with a uniqueId assignee name")
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

	var kontrolURL string
	if *flagKontrolURL != "" {
		u, err := url.Parse(*flagKontrolURL)
		if err != nil {
			log.Fatalln(err)
		}

		kontrolURL = u.String()
	}

	pubKeyPath := *flagPublicKey
	if *flagPublicKey == "" {
		pubKeyPath = conf.NewKontrol.PublicKeyFile
	}
	pubKey, err := ioutil.ReadFile(pubKeyPath)
	if err != nil {
		log.Fatalln(err)
	}
	publicKey := string(pubKey)

	privKeyPath := *flagPrivateKey
	if *flagPublicKey == "" {
		privKeyPath = conf.NewKontrol.PrivateKeyFile
	}
	privKey, err := ioutil.ReadFile(privKeyPath)
	if err != nil {
		log.Fatalln(err)
	}
	privateKey := string(privKey)

	klientFolder := "klient/development/latest"
	if *flagProdMode {
		klientFolder = "klient/production/latest"
	}

	k := &kloud.Kloud{
		Config:            conf,
		Region:            *flagRegion,
		Port:              *flagPort,
		Debug:             *flagDebug,
		UniqueId:          *flagUniqueId,
		Bucket:            kloud.NewBucket("koding-kites", klientFolder),
		KontrolURL:        kontrolURL,
		KontrolPrivateKey: privateKey,
		KontrolPublicKey:  publicKey,
	}

	k.NewKloud().Run()
}
