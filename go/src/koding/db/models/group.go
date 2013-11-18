package models

import (
	"labix.org/v2/mgo/bson"
)

type Group struct {
	ObjectId bson.ObjectId `bson:"_id" json:"-"`
	Title    string        `bson:"string" json:"string"`
}
