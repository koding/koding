package main

import (
	"io/ioutil"
	"koding/kites/common"
	"koding/kites/terraformer"
	"koding/kites/terraformer/kodingcontext"
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

	c, err := kodingcontext.Init()
	if err != nil {
		log.Fatal(err.Error())
	}
	defer kodingcontext.Close()

	k, err := terraformer.NewKite(conf, c, log)
	if err != nil {
		log.Fatal(err.Error())
	}

	if err := k.RegisterForever(k.RegisterURL(true)); err != nil {
		log.Fatal(err.Error())
	}

	k.Run()
}
