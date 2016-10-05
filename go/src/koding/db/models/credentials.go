package models

import (
	"time"

	"gopkg.in/mgo.v2/bson"
)

type Credential struct {
	Id          bson.ObjectId   `bson:"_id" json:"-"`
	Provider    string          `bson:"provider"`
	Identifier  string          `bson:"identifier"`
	Title       string          `bson:"title"`
	OriginId    bson.ObjectId   `bson:"originId"`
	Verified    bool            `bson:"verified"`
	AccessLevel string          `bson:"accessLevel"`
	Meta        *CredentialMeta `bson:"meta"`
}

type CredentialMeta struct {
	CreatedAt  time.Time `bson:"createdAt"`
	ModifiedAt time.Time `bson:"modifiedAt"`
}

type CredentialData struct {
	Id         bson.ObjectId `bson:"_id" json:"-"`
	Identifier string        `bson:"identifier"`
	Meta       bson.M        `bson:"meta"`
	OriginId   bson.ObjectId `bson:"originId"`
}
