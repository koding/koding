package main

import (
	"fmt"
	"koding/artifact"
	"koding/kites/kontrol/kontrol"

	"github.com/koding/multiconfig"
)

var Name = "kontrol"

func main() {
	m := multiconfig.New()

	conf := new(kontrol.Config)

	// Load the config, it's reads from the file, environment variables and
	// lastly from flags in order
	if err := m.Load(conf); err != nil {
		panic(err)
	}

	fmt.Printf("Kontrol loaded with following variables: %+v\n", conf)

	k := kontrol.New(conf)

	// TODO use kite's http server instead of creating another one here
	// this is used for application lifecycle management
	go artifact.StartDefaultServer(Name, conf.ArtifactPort)

	k.Run()
}
