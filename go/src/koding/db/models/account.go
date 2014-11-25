package models

import (
	"strconv"
	"time"

	"labix.org/v2/mgo/bson"
)

type Account struct {
	Id          bson.ObjectId `bson:"_id" json:"_id"`
	GlobalFlags []string      `bson:"globalFlags" json:"globalFlags"`
	SocialApiId string        `bson:"socialApiId" json:"socialApiId"`
	Profile     struct {
		Nickname  string `bson:"nickname" json:"nickname"`
		FirstName string `bson:"firstName" json:"firstName"`
		LastName  string `bson:"lastName" json:"lastName"`
		Hash      string `bson:"hash" json:"hash"`
	} `bson:"profile" json:"profile"`
	Type       string `bson:"type" json:"type"`
	Status     string `bson:"status" json:"status"`
	SystemInfo struct {
		DefaultToLastUsedEnvironment bool `json:"defaultToLastUsedEnvironment" bson:"defaultToLastUsedEnvironment"`
	} `json:"systemInfo"`
	OnlineStatus bool `bson:"onlineStatus" json:"onlineStatus"`
	Meta         struct {
		ModifiedAt time.Time `bson:"modifiedAt" json:"modifiedAt"`
		CreatedAt  time.Time `bson:"createdAt" json:"createdAt"`
		Likes      int       `json:"likes" bson:"likes"`
	} `bson:"meta" json:"meta"`
	IsExempt bool `json:"isExempt" bson:"isExempt"`
}

func (a *Account) GetSocialApiId() (int64, error) {
	return strconv.ParseInt(a.SocialApiId, 10, 64)
}
