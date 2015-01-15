package main

import "github.com/koding/kite"

type VmController struct {
	Redis    *RedisStorage
	NewRedis *NewRedisStorage
	Klient   *kite.Client
}
