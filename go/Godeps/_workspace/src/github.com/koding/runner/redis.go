package runner

import "github.com/koding/redis"

func MustInitRedisConn(c *Config) *redis.RedisSession {
	r, err := InitRedisConn(c)
	if err != nil {
		panic(err)
	}

	return r
}

func InitRedisConn(c *Config) (*redis.RedisSession, error) {
	r, err := redis.NewRedisSession(&redis.RedisConf{Server: c.Redis.URL, DB: c.Redis.DB})
	if err != nil {
		return nil, err
	}

	return r, nil
}
