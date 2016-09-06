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
	"koding/httputil"
	"koding/kites/common"
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/api/sl"
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/dnsstorage"
	"koding/kites/kloud/keycreator"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/pkg/dnsclient"
	"koding/kites/kloud/provider"
	awsprovider "koding/kites/kloud/provider/aws"
	"koding/kites/kloud/provider/disabled"
	"koding/kites/kloud/provider/softlayer"
	"koding/kites/kloud/provider/vagrant"
	"koding/kites/kloud/queue"
	"koding/kites/kloud/stackplan/stackcred"
	"koding/kites/kloud/terraformer"
	"koding/kites/kloud/userdata"

	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/koding/kite"
	kiteconfig "github.com/koding/kite/config"
	"github.com/koding/logging"
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

	// CredentialEndpoint is an API for managing stack credentials.
	CredentialEndpoint string

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

	// Defines the default name tag value to lookup a Block Device Template
	// for softlayer provider
	SLTemplateTag string

	// Overrides the default post install URL to userdata binary
	// for Softlayer instances. By default the binary is built from
	// scripts/softlayer.
	SLScriptURL string

	// MaxResults limits the max items fetched per page for each
	// AWS Describe* API calls.
	MaxResults int `default:"500"`

	// --- KLIENT DEVELOPMENT ---
	// KontrolURL to connect and to de deployed with klient
	KontrolURL string `required:"true"`

	// KlientURL overwrites the Klient deb url returned by userdata.GetLatestDeb
	// method.
	KlientURL string

	// TunnelURL overwrites default tunnelserver url. Used by vagrant provider.
	TunnelURL string

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

	SLUsername string
	SLAPIKey   string

	JanitorSecretKey     string
	VmwatcherSecretKey   string
	KloudSecretKey       string
	TerraformerSecretKey string
}

func main() {
	conf := new(Config)

	// Load the config, it's reads environment variables or from flags
	mc := multiconfig.New()
	mc.Loader = multiconfig.MultiLoader(
		&multiconfig.TagLoader{},
		&multiconfig.EnvironmentLoader{},
		&multiconfig.EnvironmentLoader{Prefix: "KONFIG_KLOUD"},
		&multiconfig.FlagLoader{},
	)

	mc.MustLoad(conf)

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

	k.ClientFunc = httputil.ClientFunc(conf.DebugMode)

	if conf.DebugMode {
		k.SetLogLevel(kite.DEBUG)
	}

	if conf.Region != "" {
		k.Config.Region = conf.Region
	}

	if conf.Environment != "" {
		k.Config.Environment = conf.Environment
	}

	if conf.SLTemplateTag != "" {
		k.Log.Warning("Default Template tag changed from %s to %s",
			softlayer.DefaultTemplateTag, conf.SLTemplateTag)
		softlayer.DefaultTemplateTag = conf.SLTemplateTag
	}

	if conf.SLScriptURL != "" {
		k.Log.Warning("Default script URL changed from %s to %s",
			softlayer.PostInstallScriptUri, conf.SLScriptURL)
		softlayer.PostInstallScriptUri = conf.SLScriptURL
	}

	// TODO(rjeczalik): refactor modelhelper methods to not use global DB
	modelhelper.Initialize(conf.MongoURL)

	sess, err := newSession(conf, k)
	if err != nil {
		panic(err)
	}

	authUsers := map[string]string{
		"kloudctl":  conf.KloudSecretKey,
		"janitor":   conf.JanitorSecretKey,
		"vmwatcher": conf.VmwatcherSecretKey,
	}

	var credURL *url.URL

	if conf.CredentialEndpoint != "" {
		if u, err := url.Parse(conf.CredentialEndpoint); err == nil {
			credURL = u
		}
	}

	if credURL == nil {
		sess.Log.Warning(`disabling "Sneaker" for storing stack credential data`)
	}

	storeOpts := &stackcred.StoreOptions{
		MongoDB: sess.DB,
		Log:     sess.Log.New("stackcred"),
		CredURL: credURL,
		Client:  httputil.DefaultRestClient(conf.DebugMode),
	}

	bp := &provider.BaseProvider{
		DB:             sess.DB,
		Log:            sess.Log,
		Kite:           sess.Kite,
		Userdata:       sess.Userdata,
		Debug:          conf.DebugMode,
		KloudSecretKey: conf.KloudSecretKey,
		CredStore:      stackcred.NewStore(storeOpts),
	}

	awsProvider := &awsprovider.Provider{
		BaseProvider: bp.New("aws"),
	}

	vagrantProvider := &vagrant.Provider{
		BaseProvider: bp.New("vagrant"),
		TunnelURL:    conf.TunnelURL,
	}

	softlayerProvider := newSoftlayerProvider(sess, conf)

	go runQueue(awsProvider, sess, conf)

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
	kld.DomainStorage = sess.DNSStorage
	kld.Domainer = sess.DNSClient
	kld.Locker = bp
	kld.Log = sess.Log
	kld.SecretKey = conf.KloudSecretKey

	err = kld.AddProvider("aws", awsProvider)
	if err != nil {
		panic(err)
	}

	err = kld.AddProvider("vagrant", vagrantProvider)
	if err != nil {
		panic(err)
	}

	err = kld.AddProvider("softlayer", softlayerProvider)
	if err != nil {
		panic(err)
	}

	// Teams/stack handling methods
	k.HandleFunc("plan", kld.Plan)
	k.HandleFunc("apply", kld.Apply)
	k.HandleFunc("migrate", kld.Migrate)
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

	for worker, key := range authUsers {
		worker, key := worker, key
		k.Authenticators[worker] = func(r *kite.Request) error {
			if r.Auth.Key != key {
				return errors.New("wrong secret key passed, you are not authenticated")
			}
			return nil
		}
	}

	return k
}

func newSession(conf *Config, k *kite.Kite) (*session.Session, error) {
	c := credentials.NewStaticCredentials(conf.AWSAccessKeyId, conf.AWSSecretAccessKey, "")

	kontrolPrivateKey, kontrolPublicKey := kontrolKeys(conf)

	klientFolder := "development/latest"
	if conf.ProdMode {
		k.Log.Info("Prod mode enabled")
		klientFolder = "production/latest"
	}

	k.Log.Info("Klient distribution channel is: %s", klientFolder)

	// Credential belongs to the `koding-kloud` user in AWS IAM's
	sess := &session.Session{
		DB:   modelhelper.Mongo,
		Kite: k,
		Userdata: &userdata.Userdata{
			Keycreator: &keycreator.Key{
				KontrolURL:        getKontrolURL(conf.KontrolURL),
				KontrolPrivateKey: kontrolPrivateKey,
				KontrolPublicKey:  kontrolPublicKey,
			},
			KlientURL: conf.KlientURL,
			Bucket:    userdata.NewBucket("koding-klient", klientFolder, c),
		},
		Terraformer: &terraformer.Options{
			Endpoint:  "http://127.0.0.1:2300/kite",
			SecretKey: conf.TerraformerSecretKey,
			Kite:      k,
		},
		Log: logging.NewCustom("kloud", conf.DebugMode),
	}

	sess.DNSStorage = dnsstorage.NewMongodbStorage(sess.DB)

	if conf.AWSAccessKeyId != "" && conf.AWSSecretAccessKey != "" {

		dnsOpts := &dnsclient.Options{
			Creds:      c,
			HostedZone: conf.HostedZone,
			Log:        logging.NewCustom("kloud-dns", conf.DebugMode),
			Debug:      conf.DebugMode,
		}

		dns, err := dnsclient.NewRoute53Client(dnsOpts)
		if err != nil {
			return nil, err
		}

		sess.DNSClient = dns

		opts := &amazon.ClientOptions{
			Credentials: c,
			Regions:     amazon.ProductionRegions,
			Log:         logging.NewCustom("kloud-koding", conf.DebugMode),
			MaxResults:  int64(conf.MaxResults),
			Debug:       conf.DebugMode,
		}

		ec2clients, err := amazon.NewClients(opts)
		if err != nil {
			return nil, err
		}

		sess.AWSClients = ec2clients
	}

	return sess, nil
}

func newSoftlayerProvider(sess *session.Session, conf *Config) kloud.Provider {
	if sess.DNSClient == nil {
		sess.Log.Warning(`disabling "softlayer" provider due to invalid/missing Route53 credentials`)

		return disabled.NewProvider("softlayer")
	}

	if conf.SLUsername == "" || conf.SLAPIKey == "" {
		sess.Log.Warning(`disabling "softlayer" provider due to missing Softlayer credentials`)

		return disabled.NewProvider("softlayer")
	}

	// TODO(rjeczalik): refactor softlayer provider to use interface instead
	dns, ok := sess.DNSStorage.(*dnsstorage.MongodbStorage)
	if !ok {
		sess.Log.Warning(`disabling "softlayer" provider due to invalid DNS storage: %T`, sess.DNSStorage)

		return disabled.NewProvider("softlayer")
	}

	// TODO(rjeczalik): refactor softlayer provider to use interface instead
	dnsClient, ok := sess.DNSClient.(*dnsclient.Route53)
	if !ok {
		sess.Log.Warning(`disabling "softlayer" provider due to invalid DNS client: %T`, sess.DNSClient)

		return disabled.NewProvider("softlayer")
	}
	sess.SLClient = sl.NewSoftlayer(conf.SLUsername, conf.SLAPIKey)

	return &softlayer.Provider{
		DB:         sess.DB,
		Log:        sess.Log.New("softlayer"),
		DNSClient:  dnsClient,
		DNSStorage: dns,
		Kite:       sess.Kite,
		Userdata:   sess.Userdata,
		SLClient:   sess.SLClient,
	}
}

func runQueue(aws kloud.Provider, sess *session.Session, conf *Config) {
	q := &queue.Queue{
		Log: sess.Log.New("queue"),
	}

	if p, ok := aws.(*awsprovider.Provider); ok {
		q.AwsProvider = p
	}

	// TODO(rjeczalik): move to config
	interv := 5 * time.Second
	if conf.ProdMode {
		interv = time.Second / 2
	}

	go q.RunCheckers(interv)
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
