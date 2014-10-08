package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"net/url"
	"os"
	"time"

	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/keys"
	"koding/kites/kloud/koding"

	"koding/kites/kloud/klient"
	"koding/kites/kloud/kloud"
	kloudprotocol "koding/kites/kloud/protocol"

	"github.com/koding/kite"
	kiteconfig "github.com/koding/kite/config"
	"github.com/koding/kite/protocol"
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
	MongoURL string `required:"true"`

	// Endpoint for fetchin plans
	PlanEndpoint string `required:"true"`

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
	HostedZone string `required:"true"`

	// Defines the default AMI Tag to use for koding provider
	AMITag string

	// --- KLIENT DEVELOPMENT ---
	// KontrolURL to connect and to de deployed with klient
	KontrolURL string `required:"true"`

	// Private key to create kite.key
	PrivateKey string `required:"true"`

	// Public key to create kite.key
	PublicKey string `required:"true"`

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

	klientFolder := "development/latest"
	checkInterval := time.Second * 5
	if conf.ProdMode {
		k.Log.Info("Prod mode enabled")
		klientFolder = "production/latest"
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
		EC2:               koding.NewEC2Client(),
		DNS:               koding.NewDNSClient(conf.HostedZone),
		Bucket:            koding.NewBucket("koding-klient", klientFolder),
		Test:              conf.TestMode,
		KontrolURL:        getKontrolURL(conf.KontrolURL),
		KontrolPrivateKey: kontrolPrivateKey,
		KontrolPublicKey:  kontrolPublicKey,
		KeyName:           keys.DeployKeyName,
		PublicKey:         keys.DeployPublicKey,
		PrivateKey:        keys.DeployPrivateKey,
		KlientPool:        klient.NewPool(k),
		InactiveMachines:  make(map[string]*time.Timer),
		DomainStorage:     koding.NewDomainStorage(db),
	}

	// be sure they they satisfy the provider interface
	var _ kloudprotocol.Provider = kodingProvider

	kodingProvider.PlanChecker = func(m *kloudprotocol.Machine) (koding.Checker, error) {
		a, err := kodingProvider.NewClient(m)
		if err != nil {
			return nil, err
		}

		return &koding.PlanChecker{
			Api:      a,
			Provider: kodingProvider,
			DB:       kodingProvider.Session,
			Kite:     kodingProvider.Kite,
			Log:      kodingProvider.Log,
			Username: m.Username,
			Machine:  m,
		}, nil
	}

	kodingProvider.PlanFetcher = func(m *kloudprotocol.Machine) (koding.Plan, error) {
		return kodingProvider.Fetcher(conf.PlanEndpoint, m)
	}

	go kodingProvider.RunChecker(checkInterval)
	go kodingProvider.RunCleaner(time.Minute)

	kld := kloud.NewWithDefaults()
	kld.Storage = kodingProvider
	kld.Locker = kodingProvider
	kld.Log = newLogger("kloud", conf.DebugMode)

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

		var args struct {
			MachineId string
			Username  string
		}

		if err := r.Args.One().Unmarshal(&args); err != nil {
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
	k.HandleFunc("resize", kld.Resize)
	k.HandleFunc("reinit", kld.Reinit)

	// let's use the wrapper function "PreparMachine" which is doing a lot of
	// things on behalf of us, like document locking, getting the machine
	// document, and so on..
	type domainFunc func(*kite.Request, *kloudprotocol.Machine) (interface{}, error)

	domainHandler := func(fn domainFunc) kite.HandlerFunc {
		return func(r *kite.Request) (resp interface{}, err error) {
			m, err := kld.PrepareMachine(r)
			if err != nil {
				return nil, err
			}

			// fake eventer to avoid panics if someone tries to use the eventer
			m.Eventer = &eventer.Events{}

			// PreparMachine is locking for us, so unlock after we are done
			defer kld.Locker.Unlock(m.Id)

			//  change it that we don't leak information
			defer func() {
				if err != nil {
					kodingProvider.Log.Error("Could not call '%s'. err: %s", r.Method, err)
					err = fmt.Errorf("Could not call '%s'. Please contact support", r.Method)
				}
			}()

			return fn(r, m)
		}
	}

	k.HandleFunc("domain.set", domainHandler(kodingProvider.DomainSet))
	k.HandleFunc("domain.unset", domainHandler(kodingProvider.DomainUnset))
	k.HandleFunc("domain.add", domainHandler(kodingProvider.DomainAdd))
	k.HandleFunc("domain.remove", domainHandler(kodingProvider.DomainRemove))

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
