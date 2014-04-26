package models

import "labix.org/v2/mgo/bson"

type Account struct {
	Id          bson.ObjectId `bson:"_id" json:"-"`
	GlobalFlags []string      `bson:"globalFlags" json:"globalFlags"`
	SocialApiId int64         `bson:"socialApiId" json:"socialApiId"`
	Profile     struct {
		Nickname  string `bson:"nickname"`
		FirstName string `bson:"firstName"`
		LastName  string `bson:"lastName"`
		Hash      string `bson:"hash"`
	} `bson:"profile"`
}
