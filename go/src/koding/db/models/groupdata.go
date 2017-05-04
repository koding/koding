package models

import "gopkg.in/mgo.v2/bson"

// GroupData holds a group's private info.
type GroupData struct {
	ID      bson.ObjectId `json:"_id" bson:"_id"`
	Slug    string        `json:"slug" bson:"slug"`
	Payload Data          `json:"payload,omitempty" bson:"payload,omitempty"`
}
