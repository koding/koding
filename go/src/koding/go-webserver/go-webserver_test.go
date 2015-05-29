package main

import (
	"koding/db/mongodb/modelhelper"

	"github.com/koding/logging"
	"github.com/koding/multiconfig"
)

type Gowebserver struct {
	Mongo     string                    `required:"true"`
	SocialApi struct{ ProxyUrl string } `required:"true"`
}

func init() {
	c := func() *Gowebserver {
		conf := new(Gowebserver)
		d := &multiconfig.DefaultLoader{
			Loader: multiconfig.MultiLoader(
				&multiconfig.EnvironmentLoader{Prefix: "KONFIG"},
			),
		}

		d.MustLoad(conf)

		return conf
	}()

	Log.SetLevel(logging.CRITICAL)

	modelhelper.Initialize(c.Mongo)
}
