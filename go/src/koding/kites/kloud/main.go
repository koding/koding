package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"koding/db/mongodb"
	"koding/kites/kloud/keys"
	"koding/kites/kloud/koding"
	"koding/tools/config"
	"koding/tools/etcd"
	"log"
	"math/rand"
	"net/url"
	"os"
	"time"

	"github.com/fatih/structure"
	"github.com/koding/kite"
	kiteconfig "github.com/koding/kite/config"
	"github.com/koding/kite/protocol"
	"github.com/koding/kloud"
	kloudprotocol "github.com/koding/kloud/protocol"
	"github.com/koding/logging"
)

func init() {
	rand.Seed(time.Now().UnixNano())
}

var (
	// ---- FLAGS ------
	flagProfile  = flag.String("c", "", "Configuration profile from file")
	flagIP       = flag.String("ip", "", "Change public ip")
	flagPort     = flag.Int("port", 3000, "Change running port")
	flagRegion   = flag.String("r", "", "Change region")
	flagEnv      = flag.String("env", "", "Change environment")
	flagUniqueId = flag.String("id", "", "Start kloud with a uniqueId assignee name")

	flagVersion  = flag.Bool("version", false, "Show version and exit")
	flagDebug    = flag.Bool("debug", false, "Enable debug mode")
	flagProdMode = flag.Bool("prod", false, "Enable production mode")

	// Deployment related flags
	flagKontrolURL = flag.String("kontrol-url", "", "Kontrol URL to be connected")
	flagPublicKey  = flag.String("public-key", "", "Public RSA key of Kontrol")
	flagPrivateKey = flag.String("private-key", "", "Private RSA key of Kontrol")

	// Kontrol registration related  flags
	flagPublic      = flag.Bool("public", false, "Start klient in local environment.")
	flagRegisterURL = flag.String("register-url", "", "Change register URL to kontrol")
	flagProxy       = flag.Bool("proxy", false, "Start klient behind a proxy")
	flagDiscovery   = flag.Bool("discovery", false, "Enable discovery mode")

	// Development related flags
	flagTest = flag.Bool("test", false, "Activate test mode (Disables VM authentication checks [useful for development], etc ..)")
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

	k := newKite()

	registerURL := k.RegisterURL(!*flagPublic)
	if *flagRegisterURL != "" {
		u, err := url.Parse(*flagRegisterURL)
		if err != nil {
			k.Log.Fatal("Couldn't parse register url: %s", err)
		}

		registerURL = u
	}

	if *flagProxy {
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

func newKite() *kite.Kite {
	k := kite.New(kloud.NAME, kloud.VERSION)
	k.Config = kiteconfig.MustGet()
	k.Config.Port = *flagPort

	if *flagRegion != "" {
		k.Config.Region = *flagRegion
	}

	if *flagEnv != "" {
		k.Config.Environment = *flagEnv
	} else {
		k.Config.Environment = config.MustConfig(*flagProfile).Environment
	}

	id := uniqueId()
	if *flagUniqueId != "" {
		id = uniqueId()
	}

	conf := config.MustConfig(*flagProfile)
	db := mongodb.NewMongoDB(conf.Mongo)

	kodingProvider := &koding.Provider{
		Log:          newLogger("koding"),
		AssigneeName: id,
		Session:      db,
		Test:         *flagTest,
	}

	if err := kodingProvider.CleanupOldData(); err != nil {
		k.Log.Warning("Cleaning up mongodb err: %s", err.Error())
	}

	klientFolder := "klient/development/latest"
	if *flagProdMode {
		klientFolder = "klient/production/latest"
	}

	privateKey, publicKey := kontrolKeys(conf)

	deployer := &KodingDeploy{
		Kite:              k,
		Log:               newLogger("kloud-deploy"),
		KontrolURL:        kontrolURL(k),
		KontrolPrivateKey: privateKey,
		KontrolPublicKey:  publicKey,
		Bucket:            newBucket("koding-kites", klientFolder),
	}

	if *flagDiscovery {
		deployer.DiscoveryURL = etcd.DefaultDiscoveryURL
	}

	kld := kloud.NewKloud()
	kld.Storage = kodingProvider
	kld.Log = newLogger("kloud")

	kld.AddProvider("koding", kodingProvider)

	injectDeploy := func(r *kite.Request) (interface{}, error) {
		d := kloudprotocol.ProviderDeploy{
			KeyName:    keys.DeployKeyName,
			PublicKey:  keys.DeployPublicKey,
			PrivateKey: keys.DeployPrivateKey,
			Username:   r.Username,
		}

		r.Context.Set("deployData", structure.Map(d))
		return true, nil
	}

	k.Handle("build", kld.NewBuild(deployer)).PreHandleFunc(injectDeploy)
	k.HandleFunc("start", kld.Start)
	k.HandleFunc("stop", kld.Stop)
	k.HandleFunc("restart", kld.Restart)
	k.HandleFunc("info", kld.Info)
	k.HandleFunc("destroy", kld.Destroy)
	k.HandleFunc("event", kld.Event)
	k.HandleFunc("report", kodingProvider.Report)

	return k
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

func newLogger(name string) logging.Logger {
	log := logging.NewLogger(name)
	logHandler := logging.NewWriterHandler(os.Stderr)
	logHandler.Colorize = true
	log.SetHandler(logHandler)

	if *flagDebug {
		log.SetLevel(logging.DEBUG)
		logHandler.SetLevel(logging.DEBUG)
	}

	return log
}

// kontrolKeys returns the private/public pairs to be used for kite.key
// generation that are deployed with klient's.
func kontrolKeys(conf *config.Config) (string, string) {
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

	return privateKey, publicKey
}

// kontrolURL returns a kontrol URL that kloud is going to connect. First it
// tries to read from kite.key. If -discovery flag is enabled it search it from
// the discovery endpoint. If -kontrol-url is given explicitly it's going to
// use that.
func kontrolURL(k *kite.Kite) string {
	kontrolURL := kiteconfig.MustGet().KontrolURL
	k.Log.Info("Reading kontrol URL from kite.key as: %s", kontrolURL)

	if *flagDiscovery {
		k.Log.Info("Discovery enabled. Searching for a production kontrol...")
		query := &protocol.KontrolQuery{
			Username: "testuser",
			// Environment: "prod",
			// Name:        "kontrol",
		}

		kontrols, err := etcd.Kontrols(query)
		if err != nil {
			k.Log.Warning("Discovery couldn't find any kontrol: %s. Going to use default URL", err)
		} else {
			index := rand.Intn(len(kontrols))
			kontrolURL = kontrols[index].URL // pick up a random kite
			k.Log.Info("Discovery found a production kontrol. Going to use it: %s", kontrolURL)
		}
	}

	if *flagKontrolURL != "" {
		u, err := url.Parse(*flagKontrolURL)
		if err != nil {
			log.Fatalln(err)
		}

		k.Log.Info("Kontrol URL is given explicitly. Going to use: %s", u.String())
		kontrolURL = u.String()
	}

	// we are going to use our final url for kontrol queries and registering
	k.Config.KontrolURL = kontrolURL

	return kontrolURL
}
