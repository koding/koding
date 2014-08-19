package main

import (
	"fmt"
	"koding/kites/kontrol/kontrol"

	"github.com/koding/multiconfig"
)

func main() {
	m := multiconfig.New()

	conf := new(kontrol.Config)

	// Load the config, it's reads from the file, environment variables and
	// lastly from flags in order
	if err := m.Load(conf); err != nil {
		panic(err)
	}

	fmt.Printf("Condig loaded with following variables: %+v\n", conf)

	k := kontrol.New(conf)
	k.Run()
}
