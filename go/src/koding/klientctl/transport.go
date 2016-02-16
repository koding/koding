package main

import "github.com/koding/kite/dnode"

// Transport is interface to talk to a remote machine.
type Transport interface {
	Tell(string, ...interface{}) (*dnode.Partial, error)
}

// ExecRes is the response of exec command on remote machine.
type ExecRes struct {
	Stdout     string `json:"stdout"`
	Stderr     string `json:"stderr"`
	ExitStatus int    `json:"exitStatus"`
}
