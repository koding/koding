package main

import (
	"koding/db/mongodb/modelhelper"

	"github.com/koding/kodingemail"
	"github.com/koding/multiconfig"
)

type Vmcleaner struct {
	Mongo string `required:"true"`
	Email struct {
		Username string `required:"username"`
		Password string `required:"password"`
	} `required:"email"`
}

var email kodingemail.Client

func initialize() {
	conf := initializeConf()

	initializeMongo(conf.Mongo)
	email = initializeEmail(conf.Email.Username, conf.Email.Password)
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

func initializeEmail(username, password string) kodingemail.Client {
	return kodingemail.NewSG(username, password)
}
