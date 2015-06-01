package main

import (
	"koding/db/mongodb/modelhelper"

	"github.com/koding/logging"
)

func init() {
	modelhelper.Initialize("localhost:27017/koding")
	Log.SetLevel(logging.CRITICAL)
}
