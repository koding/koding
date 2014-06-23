package helper

import (
	"socialapi/config"

	"github.com/koding/redis"
)

var redisConn *redis.RedisSession

func MustInitRedisConn(c *config.Config) *redis.RedisSession {
	r, err := redis.NewRedisSession(&redis.RedisConf{Server: c.Redis.URL, DB: c.Redis.DB})
	if err != nil {
		panic(err)
	}
	redisConn = r
	return r
}

func MustGetRedisConn() *redis.RedisSession {
	if redisConn == nil {
		panic("Redis connection is nil You should call \"MustInitRedisConn(server string)\" first")
	}
	return redisConn
}
