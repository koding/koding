package main

import (
	"fmt"
	"os"

	"koding/kites/tunnelproxy"

	"github.com/koding/multiconfig"
)

func die(v interface{}) {
	fmt.Fprintln(os.Stderr, v)
	os.Exit(1)
}

func main() {
	var opts tunnelproxy.ServerOptions

	m := multiconfig.New()
	m.MustLoad(&opts)

	opts.KiteName = "tunnelserver"
	opts.KiteVersion = "0.0.1"

	server, err := tunnelproxy.NewServer(&opts)
	if err != nil {
		die(err)
	}

	server.Run()
}
