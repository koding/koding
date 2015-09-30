package main

import "github.com/koding/kite/dnode"

type Transport interface {
	Tell(string, ...interface{}) (*dnode.Partial, error)
}
