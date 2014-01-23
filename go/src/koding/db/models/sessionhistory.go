package models

import (
	"labix.org/v2/mgo/bson"
	"time"
)

type SessionHistory struct {
	Id        bson.ObjectId `bson:"_id" json:"-"`
	CreatedAt time.Time     `json:"createdAt"`
	Username  string        `json:"username"`
}
