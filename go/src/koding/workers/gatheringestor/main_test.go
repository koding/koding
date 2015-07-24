package main

import "koding/db/mongodb/modelhelper"

func init() {
	// conf := initializeConf()
	modelhelper.Initialize("localhost:27017/koding")
}
