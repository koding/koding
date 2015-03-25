package main

import (
	"errors"
	_ "expvar"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	_ "net/http/pprof"
	"net/url"
	"os"

	"koding/artifact"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/dnsclient"
	"koding/kites/kloud/multiec2"
	"koding/kites/kloud/provider/koding"
	"koding/kites/kloud/userdata"

	"koding/kites/kloud/keycreator"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/kloudctl/command"

	"github.com/koding/kite"
	kiteconfig "github.com/koding/kite/config"
	"github.com/koding/logging"
	"github.com/koding/metrics"
	"github.com/koding/multiconfig"
	"github.com/mitchellh/goamz/aws"
)

var Name = "kloud"

// Config defines the configuration that Kloud needs to operate.
type Config struct {
	// ---  KLOUD SPECIFIC ---
	IP          string
	Port        int
	Region      string
	Environment string

	// Connect to Koding mongodb
	MongoURL string `required:"true"`

	// Endpoint for fetching plans
	PlanEndpoint string `required:"true"`

	// Endpoint for fetching user machine network usage
	NetworkUsageEndpoint string `required:"true"`

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

	if err := k.RegisterForever(registerURL); err != nil {
		k.Log.Fatal(err.Error())
	}

	// DataDog listens to it
	go func() {
		err := http.ListenAndServe("0.0.0.0:6060", nil)
		k.Log.Error(err.Error())
	}()

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

	if conf.AMITag != "" {
		k.Log.Warning("Default AMI Tag changed from %s to %s", koding.DefaultCustomAMITag, conf.AMITag)
		koding.DefaultCustomAMITag = conf.AMITag
	}

	klientFolder := "development/latest"
	// checkInterval := time.Second * 5
	// if conf.ProdMode {
	// 	k.Log.Info("Prod mode enabled")
	// 	klientFolder = "production/latest"
	// 	checkInterval = time.Millisecond * 500
	// }
	k.Log.Info("Klient distribution channel is: %s", klientFolder)

	modelhelper.Initialize(conf.MongoURL)
	db := modelhelper.Mongo

	kontrolPrivateKey, kontrolPublicKey := kontrolKeys(conf)

	// Credential belongs to the `koding-kloud` user in AWS IAM's
	auth := aws.Auth{
		AccessKey: "AKIAJFKDHRJ7Q5G4MOUQ",
		SecretKey: "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",
	}

	dnsInstance := dnsclient.New(conf.HostedZone, auth)

	kodingProvider := &koding.Provider{
		DB:   db,
		Log:  newLogger("kloud", conf.DebugMode),
		DNS:  dnsInstance,
		Kite: k,
		EC2Clients: multiec2.New(auth, []string{
			"us-east-1",
			"ap-southeast-1",
			"us-west-2",
			"eu-west-1",
		}),
		// KlientPool:           klient.NewPool(k),
		// InactiveMachines:     make(map[string]*time.Timer),
		NetworkUsageEndpoint: conf.NetworkUsageEndpoint,
		Userdata: &userdata.Userdata{
			Keycreator: &keycreator.Key{
				KontrolURL:        getKontrolURL(conf.KontrolURL),
				KontrolPrivateKey: kontrolPrivateKey,
				KontrolPublicKey:  kontrolPublicKey,
			},
			Bucket: userdata.NewBucket("koding-klient", klientFolder, auth),
		},
		PaymentFetcher: &koding.Payment{
			DB:              db,
			PaymentEndpoint: conf.PlanEndpoint,
		},
	}

	// be sure it satisfies the provider interface
	// var _ kloudprotocol.Provider = kodingProvider
	//
	// go kodingProvider.RunChecker(checkInterval)
	// go kodingProvider.RunCleaners(time.Minute * 60)

	stats, err := metrics.NewDogStatsD("kloud")
	if err != nil {
		panic(err)
	}

	kld := kloud.New()
	kld.Metrics = stats
	kld.PublicKeys = publickeys.NewKeys()
	// kld.Storage = kodingProvider
	// kld.DomainStorage = domainStorage
	// kld.Domainer = dnsInstance
	kld.Locker = kodingProvider
	kld.Log = newLogger(Name, conf.DebugMode)

	err = kld.AddProvider("koding", kodingProvider)
	if err != nil {
		panic(err)
	}

	// Machine handling methods
	k.HandleFunc("build", kld.Build)
	k.HandleFunc("destroy", kld.Destroy)
	k.HandleFunc("stop", kld.Stop)
	k.HandleFunc("start", kld.Start)
	k.HandleFunc("reinit", kld.Reinit)
	k.HandleFunc("restart", kld.Restart)
	k.HandleFunc("info", kld.Info)
	k.HandleFunc("event", kld.Event)
	k.HandleFunc("resize", kld.Resize)

	// Snapshot functionality
	// k.HandleFunc("createSnapshot", kld.CreateSnapshot)
	// k.HandleFunc("deleteSnapshot", kld.DeleteSnapshot)

	// Domain records handling methods
	k.HandleFunc("domain.set", kld.DomainSet)
	k.HandleFunc("domain.unset", kld.DomainUnset)
	k.HandleFunc("domain.add", kld.DomainAdd)
	k.HandleFunc("domain.remove", kld.DomainRemove)

	k.HandleHTTPFunc("/healthCheck", artifact.HealthCheckHandler(Name))
	k.HandleHTTPFunc("/version", artifact.VersionHandler())

	// This is a custom authenticator just for kloudctl
	k.Authenticators["kloudctl"] = func(r *kite.Request) error {
		if r.Auth.Key != command.KloudSecretKey {
			return errors.New("wrong secret key passed, you are not authenticated")
		}
		return nil
	}

	return k
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
