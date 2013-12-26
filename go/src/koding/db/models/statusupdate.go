package models

import "labix.org/v2/mgo/bson"

type StatusUpdate struct {
	Id           bson.ObjectId            `bson:"_id" json:"-"`
	Slug         string                   `bson:"slug"`
	Slug_        string                   `bson:"slug_"`
	Body         string                   `bson:"body"`
	OriginId     bson.ObjectId            `bson:"originId"`
	OriginType   string                   `bson:"originType"`
	Meta         Meta                     `bson:"meta"`
	RepliesCount int                      `bson:"repliesCount"`
	Group        string                   `bson:"group"`
	Counts       Count                    `bson:"counts"`
	Attachments  []map[string]interface{} `bson:"attachments"`
}

type Count struct {
	Followers int `bson:"followers"`
	Following int `bson:"following"`
}
