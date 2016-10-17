package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"koding/kites/kloud/kloud"
	"koding/kites/kloud/stack"

	"github.com/koding/multiconfig"
)

var config = multiconfig.New()

func init() {
	config.Loader = multiconfig.MultiLoader(
		&multiconfig.TagLoader{},
		&multiconfig.EnvironmentLoader{},
		&multiconfig.EnvironmentLoader{Prefix: "KONFIG_KLOUD"},
		&multiconfig.FlagLoader{},
	)

	log.SetFlags(log.LstdFlags | log.Lshortfile)
}

func main() {
	var schemaCfg SchemaConfig

	if err := config.Load(&schemaCfg); err == nil && schemaCfg.GenSchema != "" {
		if err := genSchema(schemaCfg.GenSchema); err != nil {
			log.Fatal(err)
		}

		return
	}

	var cfg kloud.Config

	if err := config.Load(&cfg); err != nil {
		log.Fatal(err)
	}

	// Load the config, it's reads environment variables or from flags
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
