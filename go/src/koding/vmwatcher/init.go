package main

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/helper"
	"time"

	"github.com/jinzhu/now"
	kiteConfig "github.com/koding/kite/config"
	"github.com/koding/multiconfig"

	"github.com/crowdmob/goamz/aws"
	"github.com/koding/kite"
	"github.com/koding/redis"
)

type Konfig struct {
	Mongo                     string `required:"true"`
	Redis                     string `required:"true"`
	Vmwatcher_AwsKey          string `required:"true"`
	Vmwatcher_AwsSecret       string `required:"true"`
	Vmwatcher_KloudSecretKey  string `required:"true"`
	Vmwatcher_KloudAddr       string `required:"true"`
	Vmwatcher_Port            string `required:"true"`
	Vmwatcher_Debug           bool
	Vmwatcher_ConnectToKlient bool
}

var (
	conf = func() *Konfig {
		conf := new(Konfig)
		multiconfig.New().MustLoad(conf)

		return conf
	}()

	port = conf.Vmwatcher_Port

	AWS_KEY    = conf.Vmwatcher_AwsKey
	AWS_SECRET = conf.Vmwatcher_AwsSecret

	// This secret key is here because this worker will be bypassed from the
	// token authentication in kloud.
	KloudSecretKey = conf.Vmwatcher_KloudSecretKey
	KloudAddr      = conf.Vmwatcher_KloudAddr

	controller *VmController

	Log = helper.CreateLogger(WorkerName, conf.Vmwatcher_Debug)
)

func initialize() {
	Log.Info("Starting...")

	controller = &VmController{}

	initializeRedis(controller)

	if conf.Vmwatcher_ConnectToKlient {
		initializeKlient(controller)
	}

	initializeMongo()

	storage = controller.Redis
	newStorage = controller.NewRedis

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
	c.NewRedis = &NewRedisStorage{Client: redisClient}
}

func initializeMongo() {
	modelhelper.Initialize(conf.Mongo)

	// Log.Debug("Connected to mongo: %s", conf.MongoURL)
}

func saveExemptUsers() {
	for _, metric := range metricsToSave {
		err := storage.ExemptSave(metric.GetName(), ExemptUsers)
		if err != nil {
			Log.Fatal(err.Error())
		}

		err = newStorage.Save(metric.GetName(), ExemptKey, ExemptUsers)
		if err != nil {
			Log.Fatal(err.Error())
		}
	}

	Log.Debug("Saved: %v users as exempt", len(ExemptUsers))
}

func initializeKlient(c *VmController) {
	var err error

	// initialize cloudwatch api client
	// arguments are: key, secret, token, expiration
	auth, err = aws.GetAuth(AWS_KEY, AWS_SECRET, "", now.BeginningOfWeek())
	if err != nil {
		Log.Fatal(err.Error())
	}

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

	// dial the kloud address
	if err := kiteClient.DialTimeout(time.Second * 10); err != nil {
		Log.Fatal("%s. Is kloud/kontrol running?", err.Error())
	}

	Log.Info("Connected to klient: %s", KloudAddr)

	c.Klient = kiteClient
}
