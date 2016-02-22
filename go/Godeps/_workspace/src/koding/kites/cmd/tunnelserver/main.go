package main

import (
	"fmt"
	"os"

	"koding/kites/tunnelproxy"

	"github.com/koding/multiconfig"
)

const (
	Name    = "tunnelkite"
	Version = "0.0.1"
)

func die(v interface{}) {
	fmt.Fprintln(os.Stderr, v)
	os.Exit(1)
}

func main() {
	var opts tunnelproxy.ServerOptions

	m := multiconfig.New()
	m.MustLoad(&opts)

	server, err := tunnelproxy.NewServer(&opts)
	if err != nil {
		die(err)
	}

	k, err := tunnelproxy.NewServerKite(server, Name, Version)
	if err != nil {
		die(err)
	}

	k.Run()
}
