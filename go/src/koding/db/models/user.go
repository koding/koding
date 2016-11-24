package models

import (
	"time"

	"gopkg.in/mgo.v2/bson"
)

type UserStatus string

const (
	UserActive      = UserStatus("active")
	UserBlocked     = UserStatus("blocked")
	UserConfirmed   = UserStatus("confirmed")
	UserDeleted     = UserStatus("deleted")
	UserUnconfirmed = UserStatus("unconfirmed")
)

type User struct {
	ObjectId       bson.ObjectId `bson:"_id" json:"_id"`
	Uid            int           `bson:"uid" json:"uid"`
	Email          string        `bson:"email" json:"email"`
	SanitizedEmail string        `bson:"sanitizedEmail" json:"sanitizedEmail"`
	LastLoginDate  time.Time     `bson:"lastLoginDate,omitempty" json:"lastLoginDate"`
	RegisteredAt   time.Time     `bson:"registeredAt" json:"registeredAt"`
	BlockedUntil   time.Time     `bson:"blockedUntil,omitempty" json:"blockedUntil"`

	// TODO left this for consistency, but should be converted into Username
	Name string `bson:"username" json:"username"`

	OldName  string     `bson:"oldUsername" json:"oldUserName"`
	Password string     `bson:"password" json:"password"`
	Status   UserStatus `bson:"status" json:"status"`
	Salt     string     `bson:"salt" json:"salt"`
	Shell    string     `bson:"shell" json:"shell"`
	SshKeys  []struct {
		Title string `bson:"title"`
		Key   string `bson:"key"`
	} `bson:"sshKeys"`
	BlockedReason string `bson:"blockedReason" json:"blockedReason"`

	EmailFrequency *EmailFrequency `bson:"emailFrequency" json:"emailFrequency"`
	Inactive       *UserInactive   `bson:"inactive,omitempty" json:"inactive"`
	ForeignAuth    ForeignAuth     `bson:"foreignAuth,omitempty" json:"-"`
	CompanyId      bson.ObjectId   `bson:"companyId,omitempty" json:"-"`
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
	Warning    string               `bson:"warning" json:"warning"`
	Assigned   bool                 `bson:"assigned" json:"assigned"`
	AssignedAt time.Time            `bson:"assignedAt" json:"assignedAt"`
	ModifiedAt time.Time            `bson:"modifiedAt" json:"modifiedAt"`
	Warnings   map[string]time.Time `bson:"warnings,omitempty" json:"warnings"`
}

type ForeignAuth struct {
	Github Github           `bson:"github" json:"-"`
	Slack  map[string]Slack `bson:"slack" json:"-"`
}

type Slack struct {
	Token string `bson:"token" json:"-"`
}

type Github struct {
	Token    string `bson:"token" json:"-"`
	Email    string
	Username string
	Scope    string
}

func (f ForeignAuth) GetAccessToken(name string) string {
	switch name {
	case "github":
		return f.Github.Token
	default:
		return ""
	}
}
