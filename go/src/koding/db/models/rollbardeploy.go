package models

import (
	"time"

	"koding/db/mongodb"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type RollbarDeploy struct {
	Id          bson.ObjectId `bson:"_id,omitempty"`
	DeployId    int           `bson:"deployId"`
	ProjectId   int           `bson:"projectId"`
	StartTime   time.Time     `bson:"startTime"`
	CodeVersion int           `bson:"codeVersion"`
	Alerted     bool
}

func (r *RollbarDeploy) UpsertByDeployId() error {
	var query = func(c *mgo.Collection) error {
		var _, err = c.Upsert(bson.M{"deployId": r.DeployId}, r)
		return err
	}

	var err = mongodb.Run(r.CollectionName(), query)

	return err
}

func (r *RollbarDeploy) CollectionName() string {
	return "deploys"
}
