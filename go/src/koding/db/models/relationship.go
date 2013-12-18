package models

import (
	"labix.org/v2/mgo/bson"
	"time"
)

type Relationship struct {
	Id         bson.ObjectId          `bson:"_id" json:"_id"`
	TargetId   bson.ObjectId          `bson:"targetId" json:"targetId"`
	TargetName string                 `bson:"targetName" json:"targetName"`
	SourceId   bson.ObjectId          `bson:"sourceId" json:"sourceId"`
	SourceName string                 `bson:"sourceName" json:"sourceName"`
	As         string                 `bson:"as" json:"as"`
	TimeStamp  time.Time              `bson:"timestamp" json:"timestamp"`
	Data       map[string]interface{} `json:"data,omitempty"`
}
