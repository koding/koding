package models

import "labix.org/v2/mgo/bson"

type Tag struct {
	Id                 bson.ObjectId `bson:"_id" json:"-"`
	Title              string        `bson:"title"`
	Slug               string        `bson:"slug"`
	Group              string        `bson:"group"`
	Status             string        `bson:"status,omitempty"`
	Counts             TagCount      `bson:"counts"`
	Category           string        `bson:"category"`
	Meta               Meta          `bson:"meta"`
	SocialApiChannelId int64         `bson:"socialApiChannelId"`
}

type TagCount struct {
	Followers int `bson:"followers"`
	Following int `bson:"following"`
	Post      int `bson:"post,omitempty"`
	Tagged    int `bson:"tagged"`
}
