package main

import (
	"koding/db/mongodb/modelhelper"
	"koding/tools/config"
	"log"

	"github.com/koding/redis"
)

var (
	conf         *config.Config
	redisClient  *redis.RedisSession
	redisStorage *RedisStorage
)

func init() {
	conf = config.MustConfig("dev")

	modelhelper.Initialize(conf.Mongo)

	var err error
	redisClient, err = redis.NewRedisSession(&redis.RedisConf{Server: conf.Redis})
	if err != nil {
		log.Fatal(err)
	}

	redisStorage = &RedisStorage{Client: redisClient}

	storage = redisStorage
}
