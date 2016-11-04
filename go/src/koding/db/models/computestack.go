package models

import (
	"koding/kites/kloud/stackstate"
	"time"

	"gopkg.in/mgo.v2/bson"
)

// ComputeStack is a document from jComputeStack collection
type ComputeStack struct {
	Id       bson.ObjectId   `bson:"_id" json:"-"`
	Machines []bson.ObjectId `bson:"machines"`

	// Points to a document in jStackTemplates
	BaseStackId bson.ObjectId `bson:"baseStackId"`

	// Points to a document in jAccounts
	OriginId bson.ObjectId `bson:"originId"`

	// Group slug.
	Group string `bson:"group"`

	// User injected credentials
	Credentials map[string][]string `bson:"credentials"`

	// TODO(rjeczalik): turn into named struct
	Status struct {
		State      string    `bson:"state"`
		Reason     string    `bson:"reason"`
		ModifiedAt time.Time `bson:"modifiedAt"`
	} `bson:"status"`

	Revision string `bson:"stackRevision"`
	Config   bson.M `bson:"config,omitempty"`
	Meta     bson.M `bson:"meta,omitempty"`
	Title    string `bson:"title,omitempty"`
}

func (c *ComputeStack) State() stackstate.State {
	return stackstate.States[c.Status.State]
}
