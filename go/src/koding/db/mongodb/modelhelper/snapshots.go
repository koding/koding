package modelhelper

import (
	"fmt"
	"koding/db/models"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

const SnapshotCol = "jSnapshots"

func GetSnapshot(id string) (*models.Snapshot, error) {
	if !bson.IsObjectIdHex(id) {
		return nil, fmt.Errorf("Not valid ObjectIdHex: '%s'", id)
	}

	snapshot := new(models.Snapshot)
	query := func(c *mgo.Collection) error {
		return c.FindId(bson.ObjectIdHex(id)).One(&snapshot)
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
