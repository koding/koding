package models

import (
	"labix.org/v2/mgo/bson"
)

type Group struct {
	Id                             bson.ObjectId            `bson:"_id" json:"-"`
	Body                           string                   `bson:"body" json:"body"`
	Title                          string                   `bson:"title" json:"title"`
	Slug                           string                   `bson:"slug" json:"slug"`
	Privacy                        string                   `bson:"privacy" json:"privacy"`
	Visibility                     string                   `bson:"visibility" json:"visibility"`
	SocialApiChannelId             string                   `bson:"socialApiChannelId" json:"socialApiChannelId"`
	SocialApiAnnouncementChannelId string                   `bson:"socialApiAnnouncementChannelId" json:"socialApiAnnouncementChannelId"`
	Parent                         []map[string]interface{} `bson:"parent" json:"parent"`
	Customize                      map[string]interface{}   `bson:"customize" json:"customize"`
	Counts                         map[string]interface{}   `bson:"counts" json:"counts"`
	Migration                      string                   `bson:"migration,omitempty" json:"migration"`
	StackTemplate                  []string                 `bson:"stackTemplates",omitempty json:"stackTemplates"`
	// DefaultChannels holds the default channels for a group, when a user joins
	// to this group, participants will be automatically added to regarding
	// channels
	DefaultChannels []string `bson:"defaultChannels",omitempty json:"defaultChannels"`
}
