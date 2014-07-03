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

	"github.com/koding/kloud"
	"github.com/koding/logging"
)

var (
	flagIP         = flag.String("ip", "", "Change public ip")
	flagPort       = flag.Int("port", 3000, "Change running port")
	flagVersion    = flag.Bool("version", false, "Show version and exit")
	flagDebug      = flag.Bool("debug", false, "Enable debug mode")
	flagProdMode   = flag.Bool("prod", false, "Enable production mode")
	flagRegion     = flag.String("r", "", "Change region")
	flagEnv        = flag.String("env", "", "Change environment")
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

	uniqueId := uniqueId()
	if *flagUniqueId != "" {
		uniqueId = uniqueId()
	}

	log := createLogger()

	mongodbStorage := &storage.MongoDB{
		Session:  mongodb.NewMongoDB(conf.Mongo),
		Assignee: uniqueId,
		Log:      log,
	}

	if err := mongodbStorage.CleanupOldData(); err != nil {
		k.Log.Notice("Cleaning up mongodb err: %s", err.Error())
	}

	k := &kloud.Kloud{
		Log:               log,
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

	go kite.RegisterForever(registerWithURL)
	<-kite.KontrolReadyNotify()

	kite.Run()
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
