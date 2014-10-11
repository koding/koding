package models

import (
	"time"

	"labix.org/v2/mgo/bson"
)

type Machine struct {
	ObjectId bson.ObjectId `bson:"_id" json:"_id"`
	Assignee struct {
		InProgress bool `bson:"inProgress" json:"inProgress"`
	} `bson:"assignee" json:"assignee"`
	CreatedAt time.Time `bson:"createdAt" json:"createdAt" `
	Domain    string    `bson:"domain" json:"domain"`
	Groups    []struct {
		Id bson.ObjectId `bson:"id" json:"id"`
	} `bson:"groups" json:"groups"`
	Label string `bson:"label" json:"label"`
	Meta  struct {
		Type         string `bson:"type" json:"type"`
		Region       string `bson:"region" json:"region"`
		SourceAmi    string `bson:"source_ami" json:"source_ami"`
		InstanceType string `bson:"instance_type" json:"instance_type"`
		StorageSize  int    `bson:"storage_size" json:"storage_size"`
		AlwaysOn     bool   `bson:"alwaysOn" json:"alwaysOn"`
	} `bson:"meta" json:"meta"`
	Provider    string        `bson:"provider" json:"provider"`
	Provisoners []interface{} `bson:"provisoners" json:"provisoners"`
	Status      struct {
		State      string    `bson:"state" json:"state"`
		ModifiedAt time.Time `bson:"modifiedAt" json:"modifiedAt"`
	} `bson:"status" json:"status"`
	Uid   string `bson:"uid" json:"uid"`
	Users []struct {
		Id    bson.ObjectId `bson:"id" json:"id"`
		Sudo  bool          `bson:"sudo" json:"sudo"`
		Owner bool          `bson:"owner" json:"owner"`
	} `bson:"users" json:"users"`
	UserDeleted bool   `bson:"userDeleted" json:"userDeleted"`
	Slug        string `bson:"slug" json:"slug"`
}
