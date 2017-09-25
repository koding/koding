package kloud

import (
	"errors"
	_ "expvar"
	"io/ioutil"
	"log"
	_ "net/http/pprof"
	"net/url"
	"os"
	"os/signal"
	"strings"
	"sync"
	"syscall"
	"time"

	"koding/api"
	"koding/artifact"
	"koding/db/mongodb/modelhelper"
	"koding/httputil"
	"koding/kites/common"
	"koding/kites/config"
	"koding/kites/keygen"
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/credential"
	"koding/kites/kloud/dnsstorage"
	"koding/kites/kloud/keycreator"
	"koding/kites/kloud/machine"
	"koding/kites/kloud/metrics"
	"koding/kites/kloud/queue"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
	"koding/kites/kloud/team"
	"koding/kites/kloud/userdata"
	kitemetrics "koding/kites/metrics"
	"koding/remoteapi"
	"koding/tools/util"
	"socialapi/workers/presence/client"

	"github.com/DataDog/datadog-go/statsd"
	"github.com/aws/aws-sdk-go/aws/credentials"
	multierror "github.com/hashicorp/go-multierror"
	"github.com/koding/kite"
	kiteconfig "github.com/koding/kite/config"
	"github.com/koding/logging"
	"golang.org/x/net/context"
)

//go:generate go run genimport.go -o import.go
//go:generate gofmt -l -w -s import.go

// Name holds kite name
var Name = "kloud"

// Kloud represents a configured kloud kite.
type Kloud struct {
	Kite   *kite.Kite
	Stack  *stack.Kloud
	Keygen *keygen.Server

	// Queue is responsible for executing checks and actions on user
	// machines. Given the interval they are queued and processed,
	// thus the naming. For example queue is responsible for
	// shutting down a non-always-on vm when it idles for more
	// than 1h.
	Queue *queue.Queue

	Stats        *statsd.Client
	metricsProxy *metrics.Publisher

	// presenceCollector publishes presence ping requests to koding for user
	// action tracking.
	presenceCollector *PresenceCollector

	closeChan chan struct{}
	closeOnce sync.Once
}

// Config defines the configuration that Kloud needs to operate.
type Config struct {
	// ---  KLOUD SPECIFIC ---
	IP          string
	Port        int
	Region      string
	Environment string

	// Connect to Koding mongodb
	MongoURL string `required:"true"`

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

	// KiteMetricsPublishURL holds the endpoint for publishing kite metrics.
	KiteMetricsPublishURL string

	// Private key to create kite.key
	PrivateKey string `required:"true"`

	// Public key to create kite.key
	PublicKey string `required:"true"`

	// Private and public key to put a ssh key into the users VM's so we can
	// have access to it. Note that these are different then from the Kontrol
	// keys.
	UserPublicKey  string `required:"true"`
	UserPrivateKey string `required:"true"`

	// Keygen configuration.
	KeygenAccessKey string
	KeygenSecretKey string
	KeygenBucket    string
	KeygenRegion    string        `default:"us-east-1"`
	KeygenTokenTTL  time.Duration `default:"3h"`

	// --- KONTROL CONFIGURATION ---
	Public      bool   // Try to register with a public ip
	RegisterURL string // Explicitly register with this given url

	// TODO(rjeczalik): rework klient.deb lookups in (kloud/userdata).NewBucket
	// and get rid of aws dependency.
	AWSAccessKeyId     string
	AWSSecretAccessKey string

	KloudSecretKey       string
	TerraformerSecretKey string

	KodingURL *config.URL // Koding base URL
	NoSneaker bool        // use Mongo for reading credentials, instead of /social/credential endpoint
}

// New gives new, registered kloud kite.
//
// If conf contains invalid or missing configuration, it return non-nil error.
func New(conf *Config) (*Kloud, error) {
	cfg, err := config.ReadKiteConfig(conf.DebugMode)
	if err != nil {
		return nil, err
	}

	if conf.KontrolURL != "" {
		cfg.KontrolURL = conf.KontrolURL
	}

	k := kite.NewWithConfig(stack.NAME, stack.VERSION, cfg)
	k.Config.Port = conf.Port

	// TODO(rjeczalik): add (*config.Config).Debug field
	if conf.DebugMode {
		k.SetLogLevel(kite.DEBUG)
	}

	if conf.Region != "" {
		k.Config.Region = conf.Region
	}

	if conf.Environment != "" {
		k.Config.Environment = conf.Environment
	}

	// TODO(rjeczalik): refactor modelhelper methods to not use global DB
	modelhelper.Initialize(conf.MongoURL)

	sess, err := newSession(conf, k)
	if err != nil {
		return nil, err
	}

	e := newEndpoints(conf)

	sess.Log.Debug("Konfig.Endpoints: %s", util.LazyJSON(e))

	authUsers := map[string]string{
		"kloudSecret": conf.KloudSecretKey,
	}

	restClient := httputil.Client(conf.DebugMode)

	storeOpts := &credential.Options{
		MongoDB: sess.DB,
		Log:     sess.Log.New("stackcred"),
		Client:  restClient,
	}

	if !conf.NoSneaker {
		storeOpts.CredURL = e.Social().WithPath("/credential").Private.URL
	}

	sess.Log.Debug("storeOpts: %+v", storeOpts)

	userPrivateKey, userPublicKey := userMachinesKeys(conf.UserPublicKey, conf.UserPrivateKey)

	stacker := &provider.Stacker{
		DB:             sess.DB,
		Log:            sess.Log,
		Kite:           sess.Kite,
		Userdata:       sess.Userdata,
		Debug:          conf.DebugMode,
		Environment:    conf.Environment,
		KloudSecretKey: conf.KloudSecretKey,
		CredStore:      credential.NewStore(storeOpts),
		TunnelURL:      conf.TunnelURL,
		SSHKey: &publickeys.Keys{
			KeyName:    publickeys.DeployKeyName,
			PrivateKey: userPrivateKey,
			PublicKey:  userPublicKey,
		},
	}

	stats := common.MustInitMetrics(Name)

	kloud := &Kloud{
		Kite:  k,
		Stack: stack.New(),
		Queue: &queue.Queue{
			Interval: 5 * time.Second,
			Log:      sess.Log.New("queue"),
			Kite:     k,
			MongoDB:  sess.DB,
		},
		closeChan: make(chan struct{}),
	}

	authFn := func(opts *api.AuthOptions) (*api.Session, error) {
		s, err := modelhelper.FetchOrCreateSession(opts.User.Username, opts.User.Team)
		if err != nil {
			return nil, err
		}

		return &api.Session{
			ClientID: s.ClientId,
			User: &api.User{
				Username: s.Username,
				Team:     s.GroupName,
			},
		}, nil
	}

	transport := &api.Transport{
		RoundTripper: storeOpts.Client.Transport,
		AuthFunc:     api.NewCache(authFn).Auth,
		Debug:        conf.DebugMode,
	}

	if conf.DebugMode {
		transport.Log = sess.Log
	}

	presenceClient := client.NewInternal(e.Social().Private.String())
	presenceClient.HTTPClient = restClient
	kloud.presenceCollector = NewPresenceCollector(presenceClient)

	kloud.Stack.Environment = conf.Environment
	kloud.Stack.Endpoints = e
	kloud.Stack.Userdata = sess.Userdata
	kloud.Stack.DescribeFunc = provider.Desc
	kloud.Stack.CredClient = credential.NewClient(storeOpts)
	kloud.Stack.MachineClient = machine.NewClient(machine.NewMongoDatabase())
	kloud.Stack.TeamClient = team.NewClient(team.NewMongoDatabase())
	kloud.Stack.RemoteClient = &remoteapi.Client{
		Client:    storeOpts.Client,
		Transport: transport,
		Endpoint:  e.Koding.Private.URL,
	}

	kloud.Stack.ContextCreator = func(ctx context.Context) context.Context {
		return session.NewContext(ctx, sess)
	}

	kloud.Stats = stats
	kloud.Stack.Metrics = stats

	// RSA key pair that we add to the newly created machine for
	// provisioning.
	kloud.Stack.PublicKeys = stacker.SSHKey
	kloud.Stack.DomainStorage = sess.DNSStorage
	kloud.Stack.Domainer = sess.DNSClient
	kloud.Stack.Locker = stacker
	kloud.Stack.Log = sess.Log
	kloud.Stack.SecretKey = conf.KloudSecretKey

	for _, p := range provider.All() {
		s := stacker.New(p)

		if err = kloud.Stack.AddProvider(p.Name, s); err != nil {
			return nil, err
		}

		kloud.Queue.Register(s)

		sess.Log.Debug("registering %q provider", p.Name)
	}

	go kloud.Queue.Run()

	if conf.KeygenAccessKey != "" && conf.KeygenSecretKey != "" {
		cfg := &keygen.Config{
			AccessKey:  conf.KeygenAccessKey,
			SecretKey:  conf.KeygenSecretKey,
			Region:     conf.KeygenRegion,
			Bucket:     conf.KeygenBucket,
			AuthExpire: conf.KeygenTokenTTL,
			AuthFunc:   kloud.Stack.ValidateUser,
			Kite:       k,
			Metrics:    stats,
		}

		kloud.Keygen = keygen.NewServer(cfg)
	} else {
		k.Log.Warning(`disabling "keygen" methods due to missing S3/STS credentials`)
	}

	publisher, err := metrics.NewPublisher(conf.KiteMetricsPublishURL)
	if err != nil {
		return nil, err
	}

	kloud.metricsProxy = publisher

	// Teams/stack handling methods.
	kloud.HandleFunc("plan", kloud.Stack.Plan)
	kloud.HandleFunc("apply", kloud.Stack.Apply)
	kloud.HandleFunc("describeStack", kloud.Stack.Status)
	kloud.HandleFunc("authenticate", kloud.Stack.Authenticate)
	kloud.HandleFunc("bootstrap", kloud.Stack.Bootstrap)
	kloud.HandleFunc("import", kloud.Stack.Import)

	// Credential handling.
	kloud.HandleFunc("credential.describe", kloud.Stack.CredentialDescribe)
	kloud.HandleFunc("credential.list", kloud.Stack.CredentialList)
	kloud.HandleFunc("credential.add", kloud.Stack.CredentialAdd)

	// Authorization handling.
	kloud.HandleFunc("auth.login", kloud.Stack.AuthLogin)
	kloud.HandleFunc("auth.passwordLogin", kloud.Stack.AuthPasswordLogin).DisableAuthentication()

	// Configuration handling.
	kloud.HandleFunc("config.metadata", kloud.Stack.ConfigMetadata)

	// Team handling.
	kloud.HandleFunc("team.list", kloud.Stack.TeamList)
	kloud.HandleFunc("team.whoami", kloud.Stack.TeamWhoami)

	// Machine handling.
	kloud.HandleFunc("machine.list", kloud.Stack.MachineList)

	// Single machine handling.
	kloud.HandleFunc("stop", kloud.Stack.Stop)
	kloud.HandleFunc("start", kloud.Stack.Start)
	kloud.HandleFunc("info", kloud.Stack.Info)
	kloud.HandleFunc("event", kloud.Stack.Event)

	// Klient proxy methods.
	kloud.HandleFunc("admin.add", kloud.Stack.AdminAdd)
	kloud.HandleFunc("admin.remove", kloud.Stack.AdminRemove)
	kloud.HandleFunc(publisher.Pattern(), publisher.Publish)

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

	go kloud.handleSignals()

	return kloud, nil
}

// HandleFunc adds our middlewares into kite handlers.
func (k *Kloud) HandleFunc(pattern string, f kite.HandlerFunc) *kite.Method {
	f = kitemetrics.WrapKiteHandler(k.Stats, pattern, f)
	f = k.presenceCollector.Collect(f)
	return k.Kite.HandleFunc(pattern, f)
}

// Close closes the underlying connections.
func (k *Kloud) Close() error {
	k.Kite.Close()

	var merr *multierror.Error
	if k.metricsProxy != nil {
		if err := k.metricsProxy.Close(); err != nil {
			merr = multierror.Append(merr, err)
		}
	}

	if err := k.Stats.Close(); err != nil {
		merr = multierror.Append(merr, err)
	}

	k.closeOnce.Do(func() {
		close(k.closeChan)
	})

	return merr.ErrorOrNil()
}

// Wait waits for Kloud to exit
func (k *Kloud) Wait() error {
	<-k.closeChan // wait for exit
	return nil
}

func (k *Kloud) handleSignals() {
	c := make(chan os.Signal, 1)
	signal.Notify(c, syscall.SIGINT, syscall.SIGTERM, syscall.SIGKILL)

	s := <-c

	k.Kite.Log.Info("%s signal received, closing kloud", s)
	k.Close()
}

func newSession(conf *Config, k *kite.Kite) (*session.Session, error) {
	c := credentials.NewStaticCredentials(conf.AWSAccessKeyId, conf.AWSSecretAccessKey, "")

	kontrolPrivateKey, kontrolPublicKey := kontrolKeys(conf)

	klientFolder := conf.Environment + "/latest"
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
			TunnelURL: conf.TunnelURL,
			Bucket:    userdata.NewBucket("koding-klient", klientFolder, c),
		},
		Terraformer: &session.TerraformerOptions{
			Endpoint:  "http://127.0.0.1:2300/kite",
			SecretKey: conf.TerraformerSecretKey,
			Kite:      k,
		},
		Log: logging.NewCustom("kloud", conf.DebugMode),
	}

	sess.DNSStorage = dnsstorage.NewMongodbStorage(sess.DB)

	return sess, nil
}

func newEndpoints(cfg *Config) *config.Endpoints {
	e := config.NewKonfig(&config.Environments{Env: cfg.Environment}).Endpoints

	if cfg.KodingURL != nil {
		e.Koding.Public = cfg.KodingURL
	}

	if cfg.TunnelURL != "" {
		if u, err := url.Parse(cfg.TunnelURL); err == nil {
			u.Path = "/kite"
			e.Tunnel = config.NewEndpoint(u.String())
		}
	}

	return e
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
