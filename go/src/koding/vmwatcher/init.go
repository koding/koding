package main

import (
	"koding/db/mongodb/modelhelper"
	"koding/tools/config"
	"socialapi/workers/helper"
	"time"

	kiteConfig "github.com/koding/kite/config"

	"github.com/crowdmob/goamz/aws"
	"github.com/koding/kite"
	"github.com/koding/redis"
)

var (
	conf = config.MustConfig("")
	port = conf.Vmwatcher.Port

	AWS_KEY    = conf.Vmwatcher.AwsKey
	AWS_SECRET = conf.Vmwatcher.AwsSecret

	// This secret key is here because this worker will be bypassed from the
	// token authentication in kloud.
	KloudSecretKey = conf.Vmwatcher.KloudSecretKey
	KloudAddr      = conf.Vmwatcher.KloudAddr

	KiteClient *kite.Client

	redisClient  *redis.RedisSession
	redisStorage *RedisStorage

	Log = helper.CreateLogger(WorkerName, false)
)

func init() {
	Log.Info("Starting %s", WorkerName)

	// initialize mongo
	modelhelper.Initialize(conf.Mongo)

	initializeRedis()

	// set globals
	redisStorage = &RedisStorage{Client: redisClient}
	storage = redisStorage

	initializeKlient()

	// save defaults
	saveExemptUsers()
	saveLimitsUnlessExists()
}

func initializeRedis() {
	var err error

	redisClient, err = redis.NewRedisSession(&redis.RedisConf{Server: conf.Redis})
	if err != nil {
		Log.Fatal(err.Error())
	}
}

func saveExemptUsers() {
	for _, metric := range metricsToSave {
		err := storage.ExemptSave(metric.GetName(), ExemptUsers)
		if err != nil {
			Log.Fatal(err.Error())
		}
	}

	Log.Info("Saved: %v users as exempt", len(ExemptUsers))
}

func saveLimitsUnlessExists() {
	for _, metric := range metricsToSave {
		err := storage.SaveLimitUnlessExists(metric.GetName(), metric.GetLimit())
		if err != nil {
			Log.Fatal(err.Error())
		}

		Log.Info("Saved limit: %v for metric: %s", metric.GetLimit(), metric.GetName())
	}
}

func initializeKlient() {
	var err error

	// initialize cloudwatch api client
	// arguments are: key, secret, token, expiration
	auth, err = aws.GetAuth(AWS_KEY, AWS_SECRET, "", startingWeek)
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
	KiteClient := k.NewClient(KloudAddr)
	KiteClient.Auth = &kite.Auth{
		Type: "kloudctl",
		Key:  KloudSecretKey,
	}

	// dial the kloud address
	if err := KiteClient.DialTimeout(time.Second * 10); err != nil {
		Log.Fatal("%s. Is kloud/kontrol running?", err.Error())
	}
}
