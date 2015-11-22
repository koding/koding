package main

import "github.com/koding/kite/dnode"

type Transport interface {
	Tell(string, ...interface{}) (*dnode.Partial, error)
}

type ExecRes struct {
	Stdout     string `json:"stdout"`
	Stderr     string `json:"stderr"`
	ExitStatus int    `json:"exitStatus"`
}
