package models

import (
	"labix.org/v2/mgo/bson"
	"time"
)

type Relationship struct {
	Id         bson.ObjectId `bson:"_id" json:"-"`
	TargetId   bson.ObjectId `bson:"targetId"`
	TargetName string        `bson:"targetName"`
	SourceId   bson.ObjectId `bson:"sourceId"`
	SourceName string        `bson:"sourceName"`
	As         string        `bson:"as"`
	TimeStamp  time.Time     `bson:"timestamp"`
}
