package main

import (
	"koding/kites/kontrol/kontrol"
	"os"

	"github.com/koding/multiconfig"
)

func main() {
	m := multiconfig.NewWithPath(os.Getenv("KONTROL_CONFIG_FILE"))

	conf := new(kontrol.Config)

	// Load the config, it's reads from the file, environment variables and
	// lastly from flags in order
	if err := m.Load(conf); err != nil {
		panic(err)
	}

	k := kontrol.New(conf)
	k.Run()
}
