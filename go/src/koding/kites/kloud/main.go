package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"net/url"
	"os"
	"time"

	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/keys"
	"koding/kites/kloud/koding"

	"github.com/koding/kite"
	kiteconfig "github.com/koding/kite/config"
	"github.com/koding/kite/protocol"
	"github.com/koding/kloud"
	kloudprotocol "github.com/koding/kloud/protocol"
	"github.com/koding/logging"
	"github.com/koding/multiconfig"
)

// Config defines the configuration that Kloud needs to operate.
type Config struct {
	// ---  KLOUD SPECIFIC ---
	IP          string
	Port        int
	Region      string
	Environment string
	Id          string

	// Connect to Koding mongodb
	MongoURL string

	// --- DEVELOPMENT CONFIG ---
	// Show version and exit if enabled
	Version bool

	// Enable debug log mode
	DebugMode bool

	// Enable production mode, operates on production channel
	ProdMode bool

	// Enable test mode, disabled some authentication checks
	TestMode bool

	// Defines the base domain for domain creation
	HostedZone string

	// Defines the default AMI Tag to use for koding provider
	AMITag string

	// --- KLIENT DEVELOPMENT ---
	// KontrolURL to connect and to de deployed with klient
	KontrolURL string

	// Private key to create kite.key
	PrivateKey string

	// Public key to create kite.key
	PublicKey string

	// Contains the users home directory to be added into a image
	TemplateDir string

	// --- KONTROL CONFIGURATION ---
	Public      bool   // Try to register with a public ip
	Proxy       bool   // Try to register behind a koding proxy
	RegisterURL string // Explicitly register with this given url
}

func main() {
	conf := new(Config)

	// Load the config, it's reads environment variables or from flags
	multiconfig.New().MustLoad(conf)

	if conf.Version {
		fmt.Println(kloud.VERSION)
		os.Exit(0)
	}

	fmt.Printf("Kloud loaded with following configuration variables: %+v\n", conf)

	if conf.HostedZone == "" {
		panic("hosted zone is not set. Pass it via -hostedzone or CONFIG_HOSTEDZONE environment variable")
	}

	k := newKite(conf)

	if conf.DebugMode {
		k.Log.Info("Debug mode enabled")
	}

	if conf.TestMode {
		k.Log.Info("Test mode enabled")
	}

	registerURL := k.RegisterURL(!conf.Public)
	if conf.RegisterURL != "" {
		u, err := url.Parse(conf.RegisterURL)
		if err != nil {
			k.Log.Fatal("Couldn't parse register url: %s", err)
		}

		registerURL = u
	}

	fmt.Printf("registering with url %+v\n", registerURL)

	if conf.Proxy {
		k.Log.Info("Proxy mode is enabled")
		// Koding proxies in production only
		proxyQuery := &protocol.KontrolQuery{
			Username:    "koding",
			Environment: "production",
			Name:        "proxy",
		}

		k.Log.Info("Seaching proxy: %#v", proxyQuery)
		go k.RegisterToProxy(registerURL, proxyQuery)
	} else {
		if err := k.RegisterForever(registerURL); err != nil {
			k.Log.Fatal(err.Error())
		}
	}

	k.Run()
}

func newKite(conf *Config) *kite.Kite {
	k := kite.New(kloud.NAME, kloud.VERSION)
	k.Config = kiteconfig.MustGet()
	k.Config.Port = conf.Port

	if conf.Region != "" {
		k.Config.Region = conf.Region
	}

	if conf.Environment != "" {
		k.Config.Environment = conf.Environment
	}

	id := uniqueId(k.Config.Port)
	if conf.Id != "" {
		id = conf.Id
	}

	if conf.AMITag != "" {
		k.Log.Warning("Default AMI Tag changed from %s to %s", koding.DefaultCustomAMITag, conf.AMITag)
		koding.DefaultCustomAMITag = conf.AMITag
	}

	klientFolder := "klient/development/latest"
	checkInterval := time.Second * 5
	if conf.ProdMode {
		k.Log.Info("Prod mode enabled")
		klientFolder = "klient/production/latest"
		checkInterval = time.Millisecond * 500
	}
	k.Log.Info("Klient distribution channel is: %s", klientFolder)

	modelhelper.Initialize(conf.MongoURL)
	db := modelhelper.Mongo

	kontrolPrivateKey, kontrolPublicKey := kontrolKeys(conf)

	kodingProvider := &koding.Provider{
		Kite:              k,
		Log:               newLogger("koding", conf.DebugMode),
		AssigneeName:      id,
		Session:           db,
		Test:              conf.TestMode,
		TemplateDir:       conf.TemplateDir,
		HostedZone:        conf.HostedZone,
		KontrolURL:        getKontrolURL(conf.KontrolURL),
		KontrolPrivateKey: kontrolPrivateKey,
		KontrolPublicKey:  kontrolPublicKey,
		Bucket:            koding.NewBucket("koding-kites", klientFolder),
		KeyName:           keys.DeployKeyName,
		PublicKey:         keys.DeployPublicKey,
		PrivateKey:        keys.DeployPrivateKey,
	}

	go kodingProvider.RunChecker(checkInterval)
	go kodingProvider.RunCleaner(time.Minute)

	kld := kloud.NewKloud()
	kld.Storage = kodingProvider
	kld.Locker = kodingProvider
	kld.Log = newLogger("kloud", conf.DebugMode)

	// be sure it compiles correctly,
	var _ kloudprotocol.Builder = kodingProvider

	err := kld.AddProvider("koding", kodingProvider)
	if err != nil {
		panic(err)
	}

	// Admin bypass if the username is koding or kloud
	k.PreHandleFunc(func(r *kite.Request) (interface{}, error) {
		if r.Args == nil {
			return nil, nil
		}

		if _, err := r.Args.SliceOfLength(1); err != nil {
			return nil, nil
		}

		args := &kloud.Controller{}
		if err := r.Args.One().Unmarshal(args); err != nil {
			return nil, nil
		}

		if koding.IsAdmin(r.Username) && args.Username != "" {
			k.Log.Warning("[%s] ADMIN COMMAND: replacing username from '%s' to '%s'",
				args.MachineId, r.Username, args.Username)
			r.Username = args.Username
		}

		return nil, nil
	})

	k.HandleFunc("build", kld.Build)
	k.HandleFunc("start", kld.Start)
	k.HandleFunc("stop", kld.Stop)
	k.HandleFunc("restart", kld.Restart)
	k.HandleFunc("info", kld.Info)
	k.HandleFunc("destroy", kld.Destroy)
	k.HandleFunc("event", kld.Event)
	k.HandleFunc("domain.set", func(r *kite.Request) (interface{}, error) {
		// let's use the helper function which is doing a lot of things on
		// behalf of us, like document locking, getting the machine document,
		// and so on..
		return kld.ControlFunc(kodingProvider.DomainSet).ServeKite(r)
	})

	return k
}

func uniqueId(port int) string {
	// TODO: add a unique identifier, for letting multiple version of the same
	// worker work on the same hostname.
	hostname, err := os.Hostname()
	if err != nil {
		panic(err) // we should not let it start
	}

	return fmt.Sprintf("%s-%s-%d", kloud.NAME, hostname, port)
}

func newLogger(name string, debug bool) logging.Logger {
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

func kontrolKeys(conf *Config) (string, string) {
	pubKey, err := ioutil.ReadFile(conf.PublicKey)
	if err != nil {
		log.Fatalln(err)
	}
	publicKey := string(pubKey)

	privKey, err := ioutil.ReadFile(conf.PrivateKey)
	if err != nil {
		log.Fatalln(err)
	}
	privateKey := string(privKey)

	return privateKey, publicKey
}

func getKontrolURL(ownURL string) string {
	// read kontrolURL from kite.key if it doesn't exist.
	kontrolURL := kiteconfig.MustGet().KontrolURL

	if ownURL != "" {
		u, err := url.Parse(ownURL)
		if err != nil {
			log.Fatalln(err)
		}

		kontrolURL = u.String()
	}

	return kontrolURL
}
