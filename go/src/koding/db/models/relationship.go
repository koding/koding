package models

import (
	"time"

	"gopkg.in/mgo.v2/bson"
)

type Relationship struct {
	Id              bson.ObjectId          `bson:"_id" json:"_id"`
	TargetId        bson.ObjectId          `bson:"targetId" json:"targetId"`
	TargetName      string                 `bson:"targetName" json:"targetName"`
	SourceId        bson.ObjectId          `bson:"sourceId" json:"sourceId"`
	SourceName      string                 `bson:"sourceName" json:"sourceName"`
	As              string                 `bson:"as" json:"as"`
	TimeStamp       time.Time              `bson:"timestamp" json:"timestamp"`
	Data            map[string]interface{} `bson:"data,omitempty" json:"data,omitempty"`
	MigrationStatus string                 `bson:"migrationStatus,omitempty"`
}
