package models

import (
	"time"

	"labix.org/v2/mgo/bson"
)

type User struct {
	ObjectId      bson.ObjectId `bson:"_id" json:"-"`
	Uid           int           `bson:"uid" json:"uid"`
	Email         string        `bson:"email" json:"email"`
	LastLoginDate time.Time     `bson:"lastLoginDate" json:"lastLoginDate"`
	RegisteredAt  time.Time     `bson:"registeredAt" json:"registeredAt"`

	// TODO left this for consistency, but should be converted into Username
	Name string `bson:"username" json:"username"`

	OldName  string `bson:"oldUsername" json:"oldUserName"`
	Password string `bson:"password" json:"password"`
	Status   string `bson:"status" json:"status"`
	Salt     string `bson:"salt" json:"salt"`
	Shell    string `bson:"shell" json:"shell"`
	SshKeys  []struct {
		Title string `bson:"title"`
		Key   string `bson:"key"`
	} `bson:"sshKeys"`

	EmailFrequency EmailFrequency `bson:"emailFrequency" json:"emailFrequency"`
}

type EmailFrequency struct {
	Global         bool `bson:"global"`
	Daily          bool `bson:"daily"`
	PrivateMessage bool `bson:"privateMessage"`
	Follow         bool `bson:"followActions"`
	Comment        bool `bson:"comment"`
	Like           bool `bson:"likeActivities"`
	GroupInvite    bool `bson:"groupInvite"`
	GroupRequest   bool `bson:"groupRequest"`
	GroupApproved  bool `bson:"groupApproved"`
	Join           bool `bson:"groupJoined"`
	Leave          bool `bson:"groupLeft"`
	Mention        bool `bson:"mention"`
}
