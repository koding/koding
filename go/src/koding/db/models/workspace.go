package models

import "labix.org/v2/mgo/bson"

type Workspace struct {
	ObjectId   bson.ObjectId `bson:"_id" json:"_id"`
	Name       string        `bson:"name" json:"name"`
	Slug       string        `bson:"slug" json:"slug"`
	MachineUID string        `bson:"machineUId" json:"machineUId"`
	Owner      string        `bson:"owner" json:"owner"`
	RootPath   string        `bson:"rootPath" json:"rootPath"`
	Layout     interface{}   `bson:"layout" json:"layout"`
}
