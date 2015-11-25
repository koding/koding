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
	"strings"
	"time"

	"golang.org/x/net/context"

	"koding/artifact"
	"koding/db/mongodb/modelhelper"
	"koding/kites/common"
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/dnsstorage"
	"koding/kites/kloud/keycreator"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/kloudctl/command"
	"koding/kites/kloud/pkg/dnsclient"
	"koding/kites/kloud/plans"
	awsprovider "koding/kites/kloud/provider/aws"
	"koding/kites/kloud/provider/koding"
	"koding/kites/kloud/queue"
	"koding/kites/kloud/userdata"

	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/koding/kite"
	kiteconfig "github.com/koding/kite/config"
	"github.com/koding/multiconfig"
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

	// Private and public key to put a ssh key into the users VM's so we can
	// have access to it. Note that these are different then from the Kontrol
	// keys.
	UserPublicKey  string `required:"true"`
	UserPrivateKey string `required:"true"`

	// --- KONTROL CONFIGURATION ---
	Public      bool   // Try to register with a public ip
	RegisterURL string // Explicitly register with this given url

	AWSAccessKeyId     string
	AWSSecretAccessKey string

	JanitorSecretKey        string
	VmwatcherSecretKey      string
	PaymentwebhookSecretKey string
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
		// This should be actually debug level 2. It outputs every single Kite
		// message and enables the kite debugging system. So enable it only if
		// you need it.
		// k.SetLogLevel(kite.DEBUG)
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

	// Credential belongs to the `koding-kloud` user in AWS IAM's
	c := credentials.NewStaticCredentials(conf.AWSAccessKeyId, conf.AWSSecretAccessKey, "")

	dnsInstance := dnsclient.NewRoute53Client(c, conf.HostedZone)
	dnsStorage := dnsstorage.NewMongodbStorage(db)
	userdata := &userdata.Userdata{
		Keycreator: &keycreator.Key{
			KontrolURL:        getKontrolURL(conf.KontrolURL),
			KontrolPrivateKey: kontrolPrivateKey,
			KontrolPublicKey:  kontrolPublicKey,
		},
		Bucket: userdata.NewBucket("koding-klient", klientFolder, c),
	}
	opts := &amazon.ClientOptions{
		Credentials: c,
		Regions: []string{
			"us-east-1",
			"ap-southeast-1",
			"us-west-2",
			"eu-west-1",
		},
		Log: common.NewLogger("kloud-koding", conf.DebugMode),
	}
	ec2clients, err := amazon.NewClientPerRegion(opts)
	if err != nil {
		panic(err)
	}

	authorizedUsers := map[string]string{
		"kloudctl":       command.KloudSecretKey,
		"janitor":        conf.JanitorSecretKey,
		"vmwatcher":      conf.VmwatcherSecretKey,
		"paymentwebhook": conf.PaymentwebhookSecretKey,
	}

	/// KODING PROVIDER ///

	kodingProvider := &koding.Provider{
		DB:         db,
		Log:        opts.Log,
		DNSClient:  dnsInstance,
		DNSStorage: dnsStorage,
		Kite:       k,
		EC2Clients: ec2clients,
		Userdata:   userdata,
		PaymentFetcher: &plans.Payment{
			PaymentEndpoint: conf.PlanEndpoint,
		},
		CheckerFetcher: &plans.KodingChecker{
			NetworkUsageEndpoint: conf.NetworkUsageEndpoint,
		},
		AuthorizedUsers: authorizedUsers,
	}

	go kodingProvider.RunCleaners(time.Minute * 60)

	/// AWS PROVIDER ///

	awsProvider := &awsprovider.Provider{
		DB:         db,
		Log:        common.NewLogger("kloud-aws", conf.DebugMode),
		DNSClient:  dnsInstance,
		DNSStorage: dnsStorage,
		Kite:       k,
		Userdata:   userdata,
	}

	// QUEUE STOPPER ///

	q := &queue.Queue{
		KodingProvider: kodingProvider,
		AwsProvider:    awsProvider,
		Log:            common.NewLogger("kloud-queue", conf.DebugMode),
	}
	go q.RunCheckers(checkInterval)

	// KLOUD DISPATCHER ///
	kloudLogger := common.NewLogger("kloud", conf.DebugMode)
	sess := &session.Session{
		DB:         db,
		Kite:       k,
		DNSClient:  dnsInstance,
		DNSStorage: dnsStorage,
		AWSClients: ec2clients,
		Userdata:   userdata,
		Log:        kloudLogger,
	}

	stats := common.MustInitMetrics(Name)

	kld := kloud.New()
	kld.ContextCreator = func(ctx context.Context) context.Context {
		return session.NewContext(ctx, sess)
	}
	kld.Metrics = stats

	userPrivateKey, userPublicKey := userMachinesKeys(conf.UserPublicKey, conf.UserPrivateKey)

	// RSA key pair that we add to the newly created machine for
	// provisioning.
	kld.PublicKeys = &publickeys.Keys{
		KeyName:    publickeys.DeployKeyName,
		PrivateKey: userPrivateKey,
		PublicKey:  userPublicKey,
	}
	kld.DomainStorage = dnsStorage
	kld.Domainer = dnsInstance
	kld.Locker = kodingProvider
	kld.Log = kloudLogger

	err = kld.AddProvider("koding", kodingProvider)
	if err != nil {
		panic(err)
	}

	err = kld.AddProvider("aws", awsProvider)
	if err != nil {
		panic(err)
	}

	// Teams/stack handling methods
	k.HandleFunc("plan", kld.Plan)
	k.HandleFunc("apply", kld.Apply)
	k.HandleFunc("describeStack", kld.Status)
	k.HandleFunc("authenticate", kld.Authenticate)
	k.HandleFunc("bootstrap", kld.Bootstrap)

	// Single machine handling
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
	k.HandleFunc("createSnapshot", kld.CreateSnapshot)
	k.HandleFunc("deleteSnapshot", kld.DeleteSnapshot)

	// Domain records handling methods
	k.HandleFunc("domain.set", kld.DomainSet)
	k.HandleFunc("domain.unset", kld.DomainUnset)
	k.HandleFunc("domain.add", kld.DomainAdd)
	k.HandleFunc("domain.remove", kld.DomainRemove)

	// Klient proxy methods
	k.HandleFunc("admin.add", kld.AdminAdd)
	k.HandleFunc("admin.remove", kld.AdminRemove)

	k.HandleHTTPFunc("/healthCheck", artifact.HealthCheckHandler(Name))
	k.HandleHTTPFunc("/version", artifact.VersionHandler())

	for w, s := range authorizedUsers {
		func(worker, secretKey string) {
			k.Authenticators[worker] = func(r *kite.Request) error {
				if r.Auth.Key != secretKey {
					return errors.New("wrong secret key passed, you are not authenticated")
				}
				return nil
			}
		}(w, s)
	}

	return k
}

func userMachinesKeys(publicPath, privatePath string) (string, string) {
	pubKey, err := ioutil.ReadFile(publicPath)
	if err != nil {
		log.Fatalln(err)
	}
	publicKey := string(pubKey)

	privKey, err := ioutil.ReadFile(privatePath)
	if err != nil {
		log.Fatalln(err)
	}
	privateKey := string(privKey)

	return strings.TrimSpace(privateKey), strings.TrimSpace(publicKey)
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
