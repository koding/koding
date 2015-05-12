package models

import (
	"time"

	"labix.org/v2/mgo/bson"
)

type Session struct {
	Id            bson.ObjectId `bson:"_id" json:"-"`
	ClientId      string        `bson:"clientId"`
	ClientIP      string        `bson:"clientIP`
	Username      string        `bson:"username"`
	OtaToken      string        `bson:"otaToken"`
	GroupName     string        `bson:"groupName"`
	GuestId       int           `bson:"guestId"`
	SessionBegan  time.Time     `bson:"sessionBegan"`
	LastAccess    time.Time     `bson:"lastAccess"`
	Impersonating bool          `bson:"impersonating"`
}
