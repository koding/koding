package main

import (
	"fmt"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/stack"
	"log"
	"net/http"
	"os"

	"github.com/koding/multiconfig"
)

func main() {
	var cfg kloud.Config

	// Load the config, it's reads environment variables or from flags
	mc := multiconfig.New()
	mc.Loader = multiconfig.MultiLoader(
		&multiconfig.TagLoader{},
		&multiconfig.EnvironmentLoader{},
		&multiconfig.EnvironmentLoader{Prefix: "KONFIG_KLOUD"},
		&multiconfig.FlagLoader{},
	)

	mc.MustLoad(&cfg)

	if cfg.Version {
		fmt.Println(stack.VERSION)
		os.Exit(0)
	}

	k, err := kloud.New(&cfg)
	if err != nil {
		log.Fatal(err)
	}

	// DataDog listens to it
	go func() {
		err := http.ListenAndServe("0.0.0.0:6060", nil)
		if err != nil {
			log.Fatal(err)
		}
	}()

	k.Kite.Run()
}
