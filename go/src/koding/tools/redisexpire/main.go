package main

import (
	"flag"
	"fmt"
	"koding/tools/config"
	"koding/tools/logger"
	"time"
	"github.com/koding/redis"

	redigo "github.com/garyburd/redigo/redis"
)

var (
	conf         *config.Config
	flagDebug    = flag.Bool("d", false, "Debug mode")
	flagProfile  = flag.String("c", "vagrant", "Configuration profile from file")
	flagDuration = flag.Duration("t", time.Hour*1, "Duration for expire in seconds - Duration flag accept any input valid for time.ParseDuration.")
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

	redisSess, err := redis.NewRedisSession(&redis.RedisConf{Server: conf.Redis})
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

		err := redisSess.Expire(sesssionKey, *flagDuration)
		if err != nil {
			log.Error("An error occured while sending expire req %v", err)
		}
	}
	log.Info("Expire script finished with config: %v", *flagProfile)
}
