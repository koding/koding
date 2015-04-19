package models

import "labix.org/v2/mgo/bson"

type Session struct {
	Id            bson.ObjectId `bson:"_id" json:"-"`
	ClientId      string        `bson:"clientId"`
	Username      string        `bson:"username"`
	GuestId       int           `bson:"guestId"`
	Impersonating bool          `bson:"impersonating"`
	OtaToken      string        `bson:"otaToken"`
}
