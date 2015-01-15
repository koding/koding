package main

import "github.com/koding/kite"

type VmController struct {
	Redis  *RedisStorage
	Klient *kite.Client
}
