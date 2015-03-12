package main

import (
	"koding/db/mongodb/modelhelper"
	"koding/tools/config"

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

	conf = &config.Config{
		SocialApi: struct{ ProxyUrl string }{},
	}

	Log.SetLevel(logging.CRITICAL)

	modelhelper.Initialize(c.Mongo)
}
