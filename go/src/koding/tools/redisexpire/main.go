package main

import (
	"flag"
	"fmt"
	"koding/databases/redis"
	"koding/tools/config"
	"koding/tools/logger"
	"time"

	redigo "github.com/garyburd/redigo/redis"
)

var (
	conf         *config.Config
	flagDebug    = flag.Bool("d", false, "Debug mode")
	flagProfile  = flag.String("c", "vagrant", "Configuration profile from file")
	flagDuration = flag.String("t", "3600", "Duration for expire in seconds")
	flagKey      = flag.String("k", "-broker-client-*", "Key for KEYS command, environment will be prepended")
)

// This script is intended for adding expiration into redis keys
func main() {
	flag.Parse()
	log := logger.New("Redis Expire Worker")

	conf = config.MustConfig(*flagProfile)

	log.SetLevel(logger.INFO)
	if *flagDebug {
		log.SetLevel(logger.DEBUG)
	}

	duration, err := time.ParseDuration(fmt.Sprintf("%ss", *flagDuration))
	if err != nil {
		panic(err)
	}

	redisSess, err := redis.NewRedisSession(conf.Redis)
	if err != nil {
		panic(err)
	}
	log.Info("Expire script started with config: %v", *flagProfile)

	initialKey := fmt.Sprintf("%s%s", conf.Environment, *flagKey)
	sesssionKeys, err := redigo.Strings(redisSess.Do("KEYS", initialKey))
	if err != nil {
		panic(err)
	}

	for _, sesssionKey := range sesssionKeys {
		log.Debug("sesssionKey %v", sesssionKey)
		time.Sleep(time.Millisecond * 10)

		err := redisSess.Expire(sesssionKey, duration)
		if err != nil {
			log.Error("An error occured while sending expire req %v", err)
		}
	}
	log.Info("Expire script finished with config: %v", *flagProfile)
}
