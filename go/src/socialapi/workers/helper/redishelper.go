package helper

import (
	"socialapi/config"

	"github.com/koding/redis"
)

var redisConn *redis.RedisSession

func MustInitRedisConn(c *config.Config) *redis.RedisSession {
	r, err := InitRedisConn(c)
	if err != nil {
		panic(err)
	}

	return r
}

func InitRedisConn(c *config.Config) (*redis.RedisSession, error) {
	// if redisconn is already created, return early, return ofthen
	if redisConn != nil {
		return redisConn, nil
	}

	r, err := redis.NewRedisSession(&redis.RedisConf{Server: c.Redis.URL, DB: c.Redis.DB})
	if err != nil {
		return nil, err
	}

	redisConn = r
	return r, nil
}

func MustGetRedisConn() *redis.RedisSession {
	if redisConn == nil {
		panic("Redis connection is nil You should call \"MustInitRedisConn(server string)\" first")
	}

	return redisConn
}
