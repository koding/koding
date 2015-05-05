package models

import "labix.org/v2/mgo/bson"

// ComputeStack is a document from jComputeStack collection
type ComputeStack struct {
	Id       bson.ObjectId   `bson:"_id" json:"-"`
	Machines []bson.ObjectId `bson:"machines"`

	// Points to a document in jStackTemplates
	BaseStackId bson.ObjectId `bson:"baseStackId"`
}
