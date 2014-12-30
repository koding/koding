package main

import (
	"koding/db/mongodb/modelhelper"
	"koding/tools/config"
	"log"

	"github.com/crowdmob/goamz/aws"
	"github.com/koding/redis"
)

var (
	conf         *config.Config
	redisClient  *redis.RedisSession
	redisStorage *RedisStorage
)

func init() {
	conf = config.MustConfig("dev")

	// initialize mongo
	modelhelper.Initialize(conf.Mongo)

	// initialize redis
	var err error
	redisClient, err = redis.NewRedisSession(&redis.RedisConf{Server: conf.Redis})
	if err != nil {
		log.Fatal(err)
	}

	redisStorage = &RedisStorage{Client: redisClient}

	storage = redisStorage

	// store exempt usernames
	for _, metric := range metricsToSave {
		err = storage.ExemptSave(metric.GetName(), ExemptUsers)
		if err != nil {
			log.Fatal(err)
		}
	}

	// initialize cloudwatch api client
	// arguments are: key, secret, token, expiration
	auth, err = aws.GetAuth(AWS_KEY, AWS_SECRET, "", startingToday)
	if err != nil {
		log.Fatal("Error: %+v\n", err)
	}
}
