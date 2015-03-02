package models

import (
	"time"

	"labix.org/v2/mgo/bson"
)

type MachineGroup struct {
	Id bson.ObjectId `bson:"id" json:"id"`
}

type MachineStatus struct {
	State      string    `bson:"state" json:"state"`
	ModifiedAt time.Time `bson:"modifiedAt" json:"modifiedAt"`
}

type MachineUser struct {
	Id        bson.ObjectId `bson:"id" json:"id"`
	Sudo      bool          `bson:"sudo" json:"sudo"`
	Owner     bool          `bson:"owner" json:"owner"`
	Permanent bool          `bson:"permanent" json:"permanent"`
	Approved  bool          `bson:"approved" json:"approved"`
}

type MachineAssignee struct {
	AssignedAt time.Time `bson:"assignedAt" json:"assignedAt"`
	InProgress bool      `bson:"inProgress" json:"inProgress"`
}

type Machine struct {
	ObjectId    bson.ObjectId   `bson:"_id" json:"_id"`
	Uid         string          `bson:"uid" json:"uid"`
	QueryString string          `bson:"queryString" json:"queryString"`
	IpAddress   string          `bson:"ipAddress" json:"ipAddress"`
	Domain      string          `bson:"domain" json:"domain"`
	Provider    string          `bson:"provider" json:"provider"`
	Label       string          `bson:"label" json:"label"`
	Slug        string          `bson:"slug" json:"slug"`
	Provisoners []bson.ObjectId `bson:"provisoners" json:"provisoners"`
	Credential  string          `bson:"credential" json:"credential"`
	Users       []MachineUser   `bson:"users" json:"users"`
	Groups      []MachineGroup  `bson:"groups" json:"groups"`
	CreatedAt   time.Time       `bson:"createdAt" json:"createdAt" `
	Status      MachineStatus   `bson:"status" json:"status"`
	Meta        interface{}     `bson:"meta" json:"meta"`
	Assignee    MachineAssignee `bson:"assignee" json:"assignee"`
	UserDeleted bool            `bson:"userDeleted" json:"userDeleted"`
}
