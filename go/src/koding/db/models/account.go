package models

import (
	"time"

	"labix.org/v2/mgo/bson"
)

type Account struct {
	Id          bson.ObjectId `bson:"_id" json:"_id"`
	GlobalFlags []string      `bson:"globalFlags" json:"globalFlags"`
	SocialApiId int64         `bson:"socialApiId" json:"socialApiId"`
	Profile     struct {
		Nickname  string `bson:"nickname"`
		FirstName string `bson:"firstName"`
		LastName  string `bson:"lastName"`
		Hash      string `bson:"hash"`
	} `bson:"profile"`
	Type       string `bson:"type" json:"type"`
	Status     string `bson:"status" json:"status"`
	SystemInfo struct {
		DefaultToLastUsedEnvironment bool `json:"defaultToLastUsedEnvironment" bson:"defaultToLastUsedEnvironment"`
	}
	OnlineStatus bool `bson:"onlineStatus" json:"onlineStatus"`
	Meta         struct {
		ModifiedAt time.Time `bson:"modifiedAt" json:"modifiedAt"`
		CreatedAt  time.Time `bson:"createdAt" json:"createdAt"`
		Likes      int       `json:"likes" bson:"likes"`
	} `bson:"meta" json:"meta"`
	IsExempt bool `json:"isExempt" bson:"isExempt"`
}
