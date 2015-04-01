package main

import (
	"koding/db/mongodb/modelhelper"
	"time"

	"github.com/cenkalti/backoff"
	"github.com/crowdmob/goamz/aws"
	"github.com/jinzhu/now"
	"github.com/koding/kite"
	kiteConfig "github.com/koding/kite/config"
	"github.com/koding/multiconfig"
	"github.com/koding/redis"
	"github.com/koding/runner"
)

type Vmwatcher struct {
	Mongo           string `required:"true"`
	Redis           string `required:"true"`
	AwsKey          string `required:"true"`
	AwsSecret       string `required:"true"`
	KloudSecretKey  string `required:"true"`
	KloudAddr       string `required:"true"`
	Port            string `required:"true"`
	Debug           bool
	ConnectToKlient bool
}

var (
	conf = func() *Vmwatcher {
		conf := new(Vmwatcher)
		d := &multiconfig.DefaultLoader{
			Loader: multiconfig.MultiLoader(
				&multiconfig.EnvironmentLoader{Prefix: "KONFIG_VMWATCHER"},
			),
		}

		d.MustLoad(conf)

		return conf
	}()

	port = conf.Port

	AWS_KEY    = conf.AwsKey
	AWS_SECRET = conf.AwsSecret

	// This secret key is here because this worker will be bypassed from the
	// token authentication in kloud.
	KloudSecretKey = conf.KloudSecretKey
	KloudAddr      = conf.KloudAddr

	controller *VmController
	storage    Storage

	Log = runner.CreateLogger(WorkerName, conf.Debug)
)

func initialize() {
	Log.Info("Starting...")

	controller = &VmController{}

	initializeRedis(controller)
	initializeAws(controller)

	if conf.ConnectToKlient {
		initializeKlient(controller)
	}

	initializeMongo()

	storage = controller.Redis

	// save defaults
	saveExemptUsers()

	// pkg default is sunday, use monday instead
	now.FirstDayMonday = true
}

func initializeRedis(c *VmController) {
	redisClient, err := redis.NewRedisSession(&redis.RedisConf{
		Server: conf.Redis,
	})

	if err != nil {
		Log.Fatal(err.Error())
	}

	// Log.Debug("Connected to redis: %s", conf.Redis)

	c.Redis = &RedisStorage{Client: redisClient}
}

func initializeMongo() {
	modelhelper.Initialize(conf.Mongo)

	// Log.Debug("Connected to mongo: %s", conf.MongoURL)
}

func initializeAws(c *VmController) {
	var err error

	// initialize cloudwatch api client
	// arguments are: key, secret, token, expiration
	auth, err = aws.GetAuth(AWS_KEY, AWS_SECRET, "", now.BeginningOfWeek())
	if err != nil {
		Log.Fatal(err.Error())
	}

	c.Aws = auth
}

func initializeKlient(c *VmController) {
	var err error

	// create new kite
	k := kite.New(WorkerName, WorkerVersion)
	config, err := kiteConfig.Get()
	if err != nil {
		Log.Fatal(err.Error())
	}

	// set skeleton config
	k.Config = config

	// create a new connection to the cloud
	kiteClient := k.NewClient(KloudAddr)
	kiteClient.Auth = &kite.Auth{
		Type: "kloudctl",
		Key:  KloudSecretKey,
	}
	kiteClient.Reconnect = true

	operation := func() error {
		return kiteClient.DialTimeout(time.Second * 10)
	}

	err = backoff.Retry(operation, backoff.NewExponentialBackOff())
	if err != nil {
		Log.Fatal("%s. Is kloud/kontrol running?", err.Error())
	}

	Log.Info("Connected to klient: %s", KloudAddr)

	c.Klient = kiteClient
}
