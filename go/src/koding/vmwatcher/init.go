package main

import (
	"koding/db/mongodb/modelhelper"
	"time"

	"github.com/cenkalti/backoff"
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
	KloudAddr       string `required:"true"`
	Port            string `required:"true"`
	SecretKey       string `required:"true"`
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

	controller *VmController
	storage    Storage

	Log = runner.CreateLogger(WorkerName, conf.Debug)
)

func initialize() {
	Log.Info("Starting...")

	controller = &VmController{}

	initializeRedis(controller)

	if conf.ConnectToKlient {
		initializeKiteClient(controller)
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

func initializeKiteClient(c *VmController) {
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
	kiteClient := k.NewClient(conf.KloudAddr)
	kiteClient.Auth = &kite.Auth{
		Type: WorkerName,
		Key:  conf.SecretKey,
	}
	kiteClient.Reconnect = true

	operation := func() error {
		return kiteClient.DialTimeout(time.Second * 10)
	}

	err = backoff.Retry(operation, backoff.NewExponentialBackOff())
	if err != nil {
		Log.Fatal("%s. Is kloud/kontrol running?", err.Error())
	}

	Log.Info("Connected to kite: %s", conf.KloudAddr)

	c.KiteClient = kiteClient
}
