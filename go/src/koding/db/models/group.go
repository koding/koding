package models

import (
	"labix.org/v2/mgo/bson"
)

type Group struct {
	Id    bson.ObjectId `bson:"_id" json:"-"`
	Title string        `bson:"string" json:"string"`
}
