package models

import (
	"labix.org/v2/mgo/bson"
	"time"
)

type Deploy struct {
	Id           bson.ObjectId `bson:"_id,omitempty"`
	ServerNumber int           `bson:"serverNumber"`
	CreatedAt    time.Time     `bson:"createdAt"`
	Version      int           `bson:"version"`
}
