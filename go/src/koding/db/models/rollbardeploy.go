package models

import (
	"time"

	"labix.org/v2/mgo/bson"
)

type RollbarDeploy struct {
	Id          bson.ObjectId `bson:"_id,omitempty"`
	DeployId    int           `bson:"deployId"`
	ProjectId   int           `bson:"projectId"`
	StartTime   time.Time     `bson:"startTime"`
	CodeVersion int           `bson:"codeVersion"`
	Alerted     bool          `bson:"alerted"`
}
