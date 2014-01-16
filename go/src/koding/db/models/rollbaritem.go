package models

import (
	"koding/db/mongodb"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"time"
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

func (r *RollbarItem) Find(findQuery bson.M) (bool, error) {
	var query = func(c *mgo.Collection) error {
		return c.Find(findQuery).One(&r)
	}

	var err = mongodb.Run(r.CollectionName(), query)

	if err != nil {
		if err.Error() == "not found" {
			return false, nil
		}

		return false, err
	}

	return true, nil
}

func (r *RollbarItem) Save() error {
	var query = func(c *mgo.Collection) error {
		return c.Insert(r)
	}

	var err = mongodb.Run(r.CollectionName(), query)

	return err
}

func (r *RollbarItem) Update(updateQuery bson.M) error {
	var query = func(c *mgo.Collection) error {
		return c.Update(bson.M{"_id": r.Id}, updateQuery)
	}

	var err = mongodb.Run(r.CollectionName(), query)

	return err
}

func (r *RollbarItem) CollectionName() string {
	return "rollbarItems"
}
