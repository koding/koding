package models

import (
	"labix.org/v2/mgo/bson"
	"time"
)

type User struct {
	ObjectId      bson.ObjectId `bson:"_id" json:"-"`
	Uid           int           `bson:"uid" json:"uid"`
	Email         string        `bson:"email" json:"email"`
	LastLoginDate time.Time     `bson:"lastLoginDate" json:"lastLoginDate"`
	RegisteredAt  time.Time     `bson:"registeredAt" json:"registeredAt"`
	// TODO left like this for consistency, but should be converted into Username
	Name     string `bson:"username" json:"username"`
	OldName  string `bson:"oldUsername" json:"oldUserName"`
	Password string `bson:"password" json:"password"`
	Status   string `bson:"status" json:"status"`
	Salt     string `bson:"salt" json:"salt"`
	Shell    string `bson:"shell" json:"shell"`
	SshKeys  []struct {
		Title string `bson:"title"`
		Key   string `bson:"key"`
	} `bson:"sshKeys"`
}
