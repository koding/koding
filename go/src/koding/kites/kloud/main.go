package main

import (
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"

	konfig "koding/kites/config"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/stack"
	"koding/kites/metrics"

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
	var cfg kloud.Config

	kloudErr := config.Load(&cfg)

	var schemaCfg SchemaConfig

	if err := config.Load(&schemaCfg); err == nil && schemaCfg.GenSchema != "" {
		if err := genSchema(schemaCfg.GenSchema); err != nil {
			log.Fatal(err)
		}

		return
	}

	if kloudErr != nil {
		log.Fatal(kloudErr)
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

	go k.Kite.Run()

	stack.Konfig = konfig.NewKonfig(&konfig.Environments{
		Env: k.Kite.Config.Environment,
	})

	// DataDog listens to it
	go func() {
		err := http.ListenAndServe("0.0.0.0:6060", nil)
		if err != nil {
			log.Fatal(err)
		}
	}()

	go func() {
		registerURL := k.Kite.RegisterURL(!cfg.Public)
		if cfg.RegisterURL != "" {
			u, err := url.Parse(cfg.RegisterURL)
			if err != nil {
				k.Kite.Log.Error("Couldn't parse register url: %s", err)
				k.Close()
				return
			}

			registerURL = u
		}

		if err := k.Kite.RegisterForever(registerURL); err != nil {
			k.Kite.Log.Error("Couldn't register: %s", err)
			k.Close()
			return
		}
	}()

	if os.Getenv("GENERATE_DATADOG_DASHBOARD") != "" {
		metrics.CreateMetricsDash()
	}

	k.Wait()

}
