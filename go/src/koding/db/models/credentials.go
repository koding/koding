package models

import "labix.org/v2/mgo/bson"

type Credential struct {
	Id        bson.ObjectId `bson:"_id" json:"-"`
	Provider  string        `bson:"provider"`
	PublicKey string        `bson:"publicKey"`
	OriginId  bson.ObjectId `bson:"originId"`
}

type CredentialData struct {
	Id        bson.ObjectId `bson:"_id" json:"-"`
	PublicKey string        `bson:"publicKey"`
	Meta      bson.M        `bson:"meta"`
	OriginId  bson.ObjectId `bson:"originId"`
}
