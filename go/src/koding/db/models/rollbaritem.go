package models

import (
	"time"

	"labix.org/v2/mgo/bson"
)

type RollbarItem struct {
	Id                bson.ObjectId `bson:"_id,omitempty" json:"-"`
	ItemId            int           `bson:"itemId"`
	ProjectId         int           `bson:"projectId"`
	CodeVersion       int           `bson:"codeVersion"`
	CreatedAt         time.Time     `bson:"createdAt"`
	TotalOccurrences  int           `bson:"totalOccurrences"`
	FirstOccurrenceId int           `bson:"firstOccurrenceId"`
	LastOccurrenceId  int           `bson:lastOccurrenceId`
	Title             string
	Level             string
	Status            string
}
