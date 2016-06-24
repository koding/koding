package main

import (
	"io/ioutil"
	"log"

	"koding/kites/terraformer"

	"github.com/koding/logging"
	"github.com/koding/multiconfig"
)

func main() {
	conf := &terraformer.Config{}
	// Load the config, reads environment variables or from flags
	multiconfig.New().MustLoad(conf)

	if !conf.TerraformDebug {
		// hashicorp.terraform outputs many logs, discard them
		log.SetOutput(ioutil.Discard)
	}

	log := logging.NewCustom(terraformer.Name, conf.Debug)

	// init terraformer
	t, err := terraformer.New(conf, log)
	if err != nil {
		log.Fatal(err.Error())
	}

	k, err := terraformer.NewKite(t, conf)
	if err != nil {
		log.Fatal(err.Error())
	}

	if err := k.RegisterForever(k.RegisterURL(true)); err != nil {
		log.Fatal(err.Error())
	}

	go k.Run()
	<-k.ServerReadyNotify()
	log.Debug("Kite Started Listening")

	// terraformer can only be closed with signals, wait for any signal
	if err := t.Wait(); err != nil {
		log.Error("Err after waiting terraformer %s", err)
	}

	k.Close()
}
