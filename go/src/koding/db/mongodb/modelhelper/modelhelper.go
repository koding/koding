package modelhelper

import (
	"koding/db/mongodb"
)

var Mongo *mongodb.MongoDB

func Initialize(url string) {
	Mongo = mongodb.NewMongoDB(url)
}

func Close() {
	if Mongo != nil {
		Mongo.Close()
	}
}
