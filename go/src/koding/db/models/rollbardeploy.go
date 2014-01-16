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
	Alerted     bool          `bson:"alerted"`
}

func (r *RollbarDeploy) SaveUniqueByDeployId() error {
	var count int
	var err error
	var findQuery = func(c *mgo.Collection) error {
		count, err = c.Find(bson.M{"deployId": r.DeployId}).Count()

		return err
	}

	err = mongodb.Run(r.CollectionName(), findQuery)
	if err != nil {
		return err
	}

	if count > 0 {
		return nil
	}

	var insertQuery = func(c *mgo.Collection) error {
		return c.Insert(r)
	}

	err = mongodb.Run(r.CollectionName(), insertQuery)

	return err
}
