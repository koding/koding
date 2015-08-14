package main

import (
	"koding/db/mongodb/modelhelper"
	"koding/tools/config"
)

var conf *config.Config

func init() {
	conf = initializeConf()
	modelhelper.Initialize(conf.Mongo)
}
