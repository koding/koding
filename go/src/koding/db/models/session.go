package models

import (
	"errors"
	"time"

	"gopkg.in/mgo.v2/bson"
)

// ErrDataKeyNotExists holds exported error for non-existing key
var ErrDataKeyNotExists = errors.New("key does not exist")

// ErrDataInvalidType holds the exported error for invalid value type
var ErrDataInvalidType = errors.New("invalid value type")

type Session struct {
	Id            bson.ObjectId `bson:"_id" json:"-"`
	ClientId      string        `bson:"clientId"`
	ClientIP      string        `bson:"clientIP"`
	Username      string        `bson:"username"`
	OtaToken      string        `bson:"otaToken"`
	GroupName     string        `bson:"groupName"`
	GuestId       int           `bson:"guestId"`
	SessionBegan  time.Time     `bson:"sessionBegan"`
	LastAccess    time.Time     `bson:"lastAccess"`
	Impersonating bool          `bson:"impersonating"`
	SessionData   Data          `bson:"sessionData,omitempty" json:"sessionData,omitempty"`
}
