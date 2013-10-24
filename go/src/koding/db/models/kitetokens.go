package models

import (
	"labix.org/v2/mgo/bson"
	"time"
)

type KiteToken struct {
	ID        bson.ObjectId `bson:"_id" json:"id"`
	Username  string        `bson:"username" json:"username"`
	Expire    time.Duration `bson:"expire" json:"expire"`
	CreatedAt time.Time     `bson:"createdAt" json:"createdAt"`
}
