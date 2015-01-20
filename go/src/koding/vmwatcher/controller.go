package main

import (
	"github.com/crowdmob/goamz/aws"
	"github.com/koding/kite"
)

type VmController struct {
	Redis  *RedisStorage
	Klient *kite.Client
	Aws    aws.Auth
}
