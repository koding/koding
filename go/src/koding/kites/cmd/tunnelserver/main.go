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

	mc := multiconfig.New()
	mc.Loader = multiconfig.MultiLoader(
		&multiconfig.TagLoader{},
		&multiconfig.EnvironmentLoader{},
		&multiconfig.EnvironmentLoader{Prefix: "KONFIG_TUNNELSERVER"},
		&multiconfig.FlagLoader{},
	)

	mc.MustLoad(&opts)

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
