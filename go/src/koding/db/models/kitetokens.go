package models

import (
	"labix.org/v2/mgo/bson"
	"time"
)

type KiteToken struct {
	ObjectId  bson.ObjectId `bson:"_id" json:"id"`
	Token     string        `bson:"token" json:"token"`
	Username  string        `bson:"username" json:"username"`
	Kites     []string      `bson:"kites" json:"kites"`
	ExpiresAt time.Time     `bson:"expiresAt" json:"expiresAt"`
	CreatedAt time.Time     `bson:"createdAt" json:"createdAt"`
}
