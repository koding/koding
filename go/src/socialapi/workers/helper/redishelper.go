package helper

import "github.com/koding/redis"

var redisConn *redis.RedisSession

func MustInitRedisConn(server string) *redis.RedisSession {
	r, err := redis.NewRedisSession(&redis.RedisConf{Server: server})
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
