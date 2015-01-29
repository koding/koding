package main

import (
	"koding/db/mongodb/modelhelper"

	"github.com/koding/multiconfig"
)

type Vmcleaner struct {
	Mongo string `required:"true"`
}

func initialize() {
	conf := initializeConf()

	initializeMongo(conf.Mongo)
}

func initializeConf() *Vmcleaner {
	var conf *Vmcleaner

	d := &multiconfig.DefaultLoader{
		Loader: multiconfig.MultiLoader(
			&multiconfig.EnvironmentLoader{Prefix: "KONFIG_VMCLEANER"},
		),
	}

	d.MustLoad(conf)

	return conf
}

func initializeMongo(mongoUrl string) {
	modelhelper.Initialize(mongoUrl)
}
