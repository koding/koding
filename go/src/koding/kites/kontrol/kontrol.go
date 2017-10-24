package main

import (
	"fmt"
	"koding/artifact"
	"koding/kites/kontrol/kontrol"
	"koding/kites/metrics"
	"os"

	"net/http"
	_ "net/http/pprof"

	"github.com/koding/kite"
	"github.com/koding/multiconfig"
)

var Name = "kontrol"

func main() {
	loader := multiconfig.MultiLoader(
		&multiconfig.TagLoader{},
		&multiconfig.EnvironmentLoader{Prefix: "KONFIG_KONTROL"},
		&multiconfig.FlagLoader{EnvPrefix: "kontrol"},
	)

	conf := new(kontrol.Config)

	// Load the config, it's reads from the file, environment variables and
	// lastly from flags in order
	if err := loader.Load(conf); err != nil {
		panic(err)
	}

	if err := multiconfig.MultiValidator(&multiconfig.RequiredValidator{}).Validate(conf); err != nil {
		panic(err)
	}

	fmt.Printf("Kontrol loaded with following variables: %+v\n", conf)

	k := kontrol.New(conf)

	k.Kite.HandleHTTPFunc("/healthCheck", artifact.HealthCheckHandler(Name))
	k.Kite.HandleHTTPFunc("/version", artifact.VersionHandler())

	if conf.Debug {
		k.Kite.SetLogLevel(kite.DEBUG)
	}

	go func() {
		// Kloud runs on 6060, so we choose 6061 for kontrol
		err := http.ListenAndServe("0.0.0.0:6061", nil)
		k.Kite.Log.Error(err.Error())
	}()

	if os.Getenv("GENERATE_DATADOG_DASHBOARD") != "" {
		metrics.CreateMetricsDash()
	}

	k.Run()
}
