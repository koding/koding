package main

import (
	"koding/db/mongodb/modelhelper"

	"github.com/koding/multiconfig"
)

type Gowebserver struct {
	Mongo string `required:"true"`
}

func init() {
	conf := func() *Gowebserver {
		conf := new(Gowebserver)
		d := &multiconfig.DefaultLoader{
			Loader: multiconfig.MultiLoader(
				&multiconfig.EnvironmentLoader{Prefix: "KONFIG"},
			),
		}

		d.MustLoad(conf)

		return conf
	}()

	modelhelper.Initialize(conf.Mongo)
}
