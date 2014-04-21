package models

import (
	"labix.org/v2/mgo/bson"
	"time"
)

type Rule struct {
	Action  string `bson:"action" json:"action"`
	Enabled bool   `bson:"enabled" json:"enabled"`
	Type    string `bson:"type" json:"type"`
	Match   string `bson:"match" json:"match"`
}

type Filter struct {
	Id         bson.ObjectId `bson:"_id" json:"-"`
	Name       string        `bson:"name" json:"name" `
	Rules      []Rule        `bson:"rules" json:"rules"`
	CreatedAt  time.Time     `bson:"createdAt" json:"createdAt"`
	ModifiedAt time.Time     `bson:"modifiedAt" json:"modifiedAt"`
}
