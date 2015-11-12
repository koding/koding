package models

import "labix.org/v2/mgo/bson"

type Proxy struct {
	Id   bson.ObjectId `bson:"_id" json:"-"`
	Name string        `bson:"name" json:"name"`
}
