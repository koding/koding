package models

import (
	"labix.org/v2/mgo/bson"
	"time"
)

type Filter struct {
	Id         bson.ObjectId `bson:"_id" json:"-"`
	Type       string        `bson:"type" json:"type"`
	Name       string        `bson:"name" json:"name" `
	Match      string        `bson:"match" json:"match"`
	CreatedAt  time.Time     `bson:"createdAt" json:"createdAt"`
	ModifiedAt time.Time     `bson:"modifiedAt" json:"modifiedAt"`
}
