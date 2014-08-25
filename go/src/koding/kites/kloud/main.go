package main

import (
	"fmt"
	"io/ioutil"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/keys"
	"koding/kites/kloud/koding"
	"log"
	"net/url"
	"os"
	"time"

	"github.com/fatih/structs"
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

	k := newKite(conf)

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

	modelhelper.Initialize(conf.MongoURL)
	db := modelhelper.Mongo

	kodingProvider := &koding.Provider{
		Kite:         k,
		Log:          newLogger("koding", conf.DebugMode),
		AssigneeName: id,
		Session:      db,
		Test:         conf.TestMode,
		TemplateDir:  conf.TemplateDir,
	}

	go kodingProvider.RunChecker(time.Second * 10)
	go kodingProvider.RunCleaner(time.Minute)

	klientFolder := "klient/development/latest"
	if conf.ProdMode {
		klientFolder = "klient/production/latest"
	}

	privateKey, publicKey := kontrolKeys(conf)

	deployer := &KodingDeploy{
		Kite:              k,
		Log:               newLogger("kloud-deploy", conf.DebugMode),
		KontrolURL:        kontrolURL(conf.KontrolURL),
		KontrolPrivateKey: privateKey,
		KontrolPublicKey:  publicKey,
		Bucket:            newBucket("koding-kites", klientFolder),
		DB:                db,
	}

	kld := kloud.NewKloud()
	kld.Storage = kodingProvider
	kld.Log = newLogger("kloud", conf.DebugMode)

	// check if our provider
	var _ kloudprotocol.Builder = kodingProvider

	err := kld.AddProvider("koding", kodingProvider)
	if err != nil {
		panic(err)
	}

	injectDeploy := func(r *kite.Request) (interface{}, error) {
		d := kloudprotocol.ProviderDeploy{
			KeyName:    keys.DeployKeyName,
			PublicKey:  keys.DeployPublicKey,
			PrivateKey: keys.DeployPrivateKey,
			Username:   r.Username,
		}

		r.Context.Set("deployData", structs.Map(d))
		return true, nil
	}

	k.Handle("build", kld.NewBuild(deployer)).PreHandleFunc(injectDeploy)
	k.HandleFunc("start", kld.Start)
	k.HandleFunc("stop", kld.Stop)
	k.HandleFunc("restart", kld.Restart)
	k.HandleFunc("info", kld.Info)
	k.HandleFunc("destroy", kld.Destroy)
	k.HandleFunc("event", kld.Event)

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

func kontrolURL(ownURL string) string {
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
