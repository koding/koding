package main

import (
	"koding/db/mongodb/modelhelper"

	"github.com/koding/logging"
	"github.com/koding/multiconfig"
)

type Tokenizer struct {
	Mongo string `required:"true"`
}

func init() {
	conf := new(Tokenizer)

	(&multiconfig.DefaultLoader{
		Loader: multiconfig.MultiLoader(&multiconfig.EnvironmentLoader{Prefix: "KONFIG"}),
	}).MustLoad(conf)

	Log.SetLevel(logging.CRITICAL)

	modelhelper.Initialize(conf.Mongo)
}
