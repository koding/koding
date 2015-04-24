package main

import (
	"io/ioutil"
	"koding/kites/common"
	"koding/kites/terraformer"
	"log"

	"github.com/koding/multiconfig"
)

func main() {
	conf := &terraformer.Config{}
	// Load the config, reads environment variables or from flags
	multiconfig.New().MustLoad(conf)

	if !conf.Debug {
		// hashicorp.terraform outputs many logs, discard them
		log.SetOutput(ioutil.Discard)
	}

	log := common.NewLogger(terraformer.Name, conf.Debug)

	// init terraformer
	t, err := terraformer.New(conf, log)
	if err != nil {
		log.Fatal(err.Error())
	}
	defer t.Close()

	// init terraformer's kite
	k, err := t.Kite()
	if err != nil {
		log.Fatal(err.Error())
	}
	defer k.Close()

	if err := k.RegisterForever(k.RegisterURL(true)); err != nil {
		log.Fatal(err.Error())
	}

	k.Run()
}
