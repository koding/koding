package models

import (
	"time"

	"labix.org/v2/mgo/bson"
)

type Filter struct {
	Id         bson.ObjectId `bson:"_id" json:"-"`
	Enabled    bool          `bson:"enabled" json:"enabled"`
	Name       string        `bson:"name" json:"name" `
	Rules      []Rule        `bson:"rules" json:"rules"`
	CreatedAt  time.Time     `bson:"createdAt" json:"createdAt"`
	ModifiedAt time.Time     `bson:"modifiedAt" json:"modifiedAt"`
}

type Rule struct {
	Enabled bool   `bson:"enabled" json:"enabled"`
	Action  string `bson:"action" json:"action"`
	Type    string `bson:"type" json:"type"`
	Match   string `bson:"match" json:"match"`
}
