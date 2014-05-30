package models

import (
	"labix.org/v2/mgo/bson"
)

type Group struct {
	Id                 bson.ObjectId            `bson:"_id" json:"-"`
	Body               string                   `bson:"body" json:"body"`
	Title              string                   `bson:"title" json:"title"`
	Slug               string                   `bson:"slug" json:"slug"`
	Privacy            string                   `bson:"privacy" json:"privacy"`
	Visibility         string                   `bson:"visibility" json:"visibility"`
	SocialApiChannelId string                   `bson:"socialApiChannelId" json:"socialApiChannelId"`
	Parent             []map[string]interface{} `bson:"parent" json:"parent"`
	Customize          map[string]interface{}   `bson:"customize" json:"customize"`
	Counts             map[string]interface{}   `bson:"counts" json:"counts"`
}
