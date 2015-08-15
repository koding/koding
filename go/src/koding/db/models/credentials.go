package models

import "labix.org/v2/mgo/bson"

type Credential struct {
	Id         bson.ObjectId `bson:"_id" json:"-"`
	Provider   string        `bson:"provider"`
	Identifier string        `bson:"identifier"`
	OriginId   bson.ObjectId `bson:"originId"`
}

type CredentialData struct {
	Id         bson.ObjectId `bson:"_id" json:"-"`
	Identifier string        `bson:"identifier"`
	Meta       bson.M        `bson:"meta"`
	OriginId   bson.ObjectId `bson:"originId"`
}
