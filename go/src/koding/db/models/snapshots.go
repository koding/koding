package models

import (
	"time"

	"labix.org/v2/mgo/bson"
)

type Snapshot struct {
	Id          bson.ObjectId `bson:"_id" json:"-"`
	OriginId    bson.ObjectId `bson:"originId"`
	MachineId   bson.ObjectId `bson:"machineId"`
	SnapshotId  string        `bson:"snapshotId"`
	StorageSize string        `bson:"storageSize"`
	Region      string        `bson:"region"`
	Label       string        `bson:"label"`
	CreatedAt   time.Time     `bson:"createdAt"`
	Username    string        `bson:"-"`
}
