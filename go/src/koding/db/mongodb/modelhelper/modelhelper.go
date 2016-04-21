package modelhelper

import (
	"koding/db/mongodb"

	"github.com/mitchellh/mapstructure"
	"gopkg.in/mgo.v2/bson"
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

func BsonDecode(m bson.M, v interface{}) error {
	config := &mapstructure.DecoderConfig{
		Result:  v,
		TagName: "bson",
	}

	decoder, err := mapstructure.NewDecoder(config)
	if err != nil {
		return err
	}

	return decoder.Decode(m)
}

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}

	return nil
}
