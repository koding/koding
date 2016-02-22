package modelhelper

import (
	"koding/db/models"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

const SnapshotCol = "jSnapshots"

func GetSnapshot(snapshotId string) (*models.Snapshot, error) {
	snapshot := new(models.Snapshot)
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"snapshotId": snapshotId}).One(&snapshot)
	}

	if err := Mongo.Run(SnapshotCol, query); err != nil {
		return nil, err
	}

	return snapshot, nil
}

func DeleteSnapshot(snapshotId string) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"snapshotId": snapshotId})
	}

	return Mongo.Run(SnapshotCol, query)
}
