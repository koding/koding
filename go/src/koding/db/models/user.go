package models

import "labix.org/v2/mgo/bson"

type User struct {
	ObjectId bson.ObjectId `bson:"_id"`
	Uid      int           `bson:"uid"`
	Name     string        `bson:"username"`
	OldName  string        `bson:"oldUsername"`
	Password string        `bson:"password"`
	Salt     string        `bson:"salt"`
	Shell    string        `bson:"shell"`
	SshKeys  []struct {
		Title string `bson:"title"`
		Key   string `bson:"key"`
	} `bson:"sshKeys"`
}
