package models

import "labix.org/v2/mgo/bson"

type Account struct {
	ObjectId bson.ObjectId `bson:"_id" json:"-"`
	Profile  struct {
		Nickname  string `bson:"nickname"`
		FirstName string `bson:"firstName"`
		LastName  string `bson:"lastName"`
		Hash      string `bson:"hash"`
	} `bson:"profile"`
}
