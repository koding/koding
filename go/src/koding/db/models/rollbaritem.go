package models

import (
	"time"

	"koding/db/mongodb"

	"labix.org/v2/mgo"
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

func (r *RollbarItem) UpsertByItemId() error {
	var query = func(c *mgo.Collection) error {
		var _, err = c.Upsert(bson.M{"itemId": r.ItemId}, r)
		return err
	}

	var err = mongodb.Run(r.CollectionName(), query)

	return err
}

func (r *RollbarItem) FindByCodeVersion() ([]*RollbarItem, error) {
	var foundItems []*RollbarItem
	var findQuery = func(c *mgo.Collection) error {
		return c.Find(bson.M{"codeVersion": r.CodeVersion}).All(&foundItems)
	}

	var err = mongodb.Run(r.CollectionName(), findQuery)

	return foundItems, err
}

func (r *RollbarItem) CollectionName() string {
	return "rollbarItems"
}
