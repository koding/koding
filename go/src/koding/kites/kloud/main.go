package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"koding/db/mongodb"
	"koding/kites/kloud/storage"
	"koding/tools/config"
	"log"
	"net/url"
	"os"

	"github.com/koding/kite/protocol"
	"github.com/koding/kloud"
)

var (
	flagIP      = flag.String("ip", "", "Change public ip")
	flagPort    = flag.Int("port", 3000, "Change running port")
	flagVersion = flag.Bool("version", false, "Show version and exit")

	flagDebug       = flag.Bool("debug", false, "Enable debug mode")
	flagProdMode    = flag.Bool("prod", false, "Enable production mode")
	flagRegion      = flag.String("r", "", "Change region")
	flagLocal       = flag.Bool("local", false, "Start klient in local environment.")
	flagRegisterURL = flag.String("register-url", "", "Change register URL to kontrol")
	flagEnv         = flag.String("env", "", "Change environment")
	flagProfile     = flag.String("c", "", "Configuration profile from file")

	flagKontrolURL = flag.String("kontrol-url", "", "Kontrol URL to be connected")
	flagPublicKey  = flag.String("public-key", "", "Public RSA key of Kontrol")
	flagPrivateKey = flag.String("private-key", "", "Private RSA key of Kontrol")
	flagUniqueId   = flag.String("id", "", "Start kloud with a uniqueId assignee name")

	flagProxy = flag.Bool("proxy", false, "Start klient behind a proxy")
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

	if *flagEnv != "" {
		conf.Environment = *flagEnv
	}

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

	id := uniqueId()
	if *flagUniqueId != "" {
		id = uniqueId()
	}

	mongodbLog := kloud.Logger("kloud-storage", *flagDebug)
	mongodbStorage := &storage.MongoDB{
		Session:      mongodb.NewMongoDB(conf.Mongo),
		AssigneeName: id,
		Log:          mongodbLog,
	}

	if err := mongodbStorage.CleanupOldData(); err != nil {
		mongodbLog.Notice("Cleaning up mongodb err: %s", err.Error())
	}

	k := &kloud.Kloud{
		Storage:           mongodbStorage,
		Region:            *flagRegion,
		Environment:       conf.Environment,
		Port:              *flagPort,
		Debug:             *flagDebug,
		Bucket:            kloud.NewBucket("koding-kites", klientFolder),
		KontrolURL:        kontrolURL,
		KontrolPrivateKey: privateKey,
		KontrolPublicKey:  publicKey,
	}

	kite := k.NewKloud()

	registerURL := kite.RegisterURL(*flagLocal)
	if *flagRegisterURL != "" {
		u, err := url.Parse(*flagRegisterURL)
		if err != nil {
			k.Log.Fatal("Couldn't parse register url: %s", err)
		}

		registerURL = u
	}

	kite.Log.Info("Going to register to kontrol with URL: %s", registerURL)
	if *flagProxy {
		kite.Log.Info("Proxy mode is enabled")
		// Koding proxies in production only
		proxyQuery := &protocol.KontrolQuery{
			Username:    "koding",
			Environment: "production",
			Name:        "proxy",
		}

		k.Log.Info("Seaching proxy: %#v", proxyQuery)
		go kite.RegisterToProxy(registerURL, proxyQuery)
	} else {
		if err := kite.RegisterForever(registerURL); err != nil {
			kite.Log.Fatal(err.Error())
		}
	}

	kite.Run()
}

func uniqueId() string {
	// TODO: add a unique identifier, for letting multiple version of the same
	// worker work on the same hostname.
	hostname, err := os.Hostname()
	if err != nil {
		panic(err) // we should not let it start
	}

	return fmt.Sprintf("%s-%s", kloud.NAME, hostname)
}
