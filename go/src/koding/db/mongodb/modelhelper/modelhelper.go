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

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}

	return nil
}
