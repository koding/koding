package models

import (
	"time"

	"labix.org/v2/mgo/bson"
)

type User struct {
	ObjectId      bson.ObjectId `bson:"_id" json:"-"`
	Uid           int           `bson:"uid" json:"uid"`
	Email         string        `bson:"email" json:"email"`
	LastLoginDate time.Time     `bson:"lastLoginDate,omitempty" json:"lastLoginDate"`
	RegisteredAt  time.Time     `bson:"registeredAt" json:"registeredAt"`
	BlockedUntil  time.Time     `bson:"blockedUntil" json:"blockedUntil"`

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

	BlockedReason string `bson:"blockedReason" json:"blockedReason"`

	EmailFrequency EmailFrequency `bson:"emailFrequency" json:"emailFrequency"`
	Inactive       UserInactive   `bson:"inactive,omitempty" json:"inactive"`
}

type EmailFrequency struct {
	Global            bool   `bson:"global"`
	Daily             bool   `bson:"daily"`
	PrivateMessage    bool   `bson:"privateMessage"`
	Follow            bool   `bson:"followActions"`
	Comment           bool   `bson:"comment"`
	Like              bool   `bson:"likeActivities"`
	GroupInvite       bool   `bson:"groupInvite"`
	GroupRequest      bool   `bson:"groupRequest"`
	GroupApproved     bool   `bson:"groupApproved"`
	Join              bool   `bson:"groupJoined"`
	Leave             bool   `bson:"groupLeft"`
	Mention           bool   `bson:"mention"`
	NotificationDelay string `bson:"pmNotificationDelay"`
}

type UserInactive struct {
	Warning     int                     `bson:"warning" json:"warning"`
	Assigned    bool                    `bson:"assigned" json:"assigned"`
	AssignedAt  time.Time               `bson:"assignedAt" json:"assignedAt"`
	ModifiedAt  time.Time               `bson:"modifiedAt" json:"modifiedAt"`
	WarningTime UserInactiveWarningTime `bson:"warning_time,omitempty" json:"warning_time"`
}

type UserInactiveWarningTime struct {
	One   time.Time `bson:"1,omitempty" json:"1"`
	Two   time.Time `bson:"2,omitempty" json:"2"`
	Three time.Time `bson:"3,omitempty" json:"3"`
	Four  time.Time `bson:"4,omitempty" json:"4"`
}
