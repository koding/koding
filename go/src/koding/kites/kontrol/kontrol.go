package main

import (
	"fmt"
	"koding/artifact"
	"koding/kites/kontrol/kontrol"

	"github.com/koding/kite"
	"github.com/koding/multiconfig"
)

var Name = "kontrol"

func main() {
	loader := multiconfig.MultiLoader(
		&multiconfig.TagLoader{},
		&multiconfig.EnvironmentLoader{Prefix: "kontrol"},
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

	k.Run()
}
