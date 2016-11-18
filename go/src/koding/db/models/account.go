package models

import (
	"strconv"
	"time"

	"gopkg.in/mgo.v2/bson"
)

type Account struct {
	Id          bson.ObjectId  `bson:"_id" json:"_id"`
	GlobalFlags []string       `bson:"globalFlags" json:"globalFlags"`
	SocialApiId string         `bson:"socialApiId" json:"socialApiId"`
	Type        string         `bson:"type" json:"type"`
	Status      string         `bson:"status" json:"status"`
	Profile     AccountProfile `bson:"profile" json:"profile"`
	SystemInfo  struct {
		DefaultToLastUsedEnvironment bool `json:"defaultToLastUsedEnvironment" bson:"defaultToLastUsedEnvironment"`
	} `json:"systemInfo"`
	Meta struct {
		ModifiedAt time.Time `bson:"modifiedAt" json:"modifiedAt"`
		CreatedAt  time.Time `bson:"createdAt" json:"createdAt"`
		Likes      int       `json:"likes" bson:"likes"`
	} `bson:"meta" json:"meta"`
	IsExempt                bool `json:"isExempt" bson:"isExempt"`
	LastLoginTimezoneOffset int  `json:"lastLoginTimezoneOffset" bson:"lastLoginTimezoneOffset"`
}

type AccountProfile struct {
	Nickname  string `bson:"nickname" json:"nickname"`
	FirstName string `bson:"firstName" json:"firstName"`
	LastName  string `bson:"lastName" json:"lastName"`
	Hash      string `bson:"hash" json:"hash"`
}

func (a *Account) GetSocialApiId() (int64, error) {
	if a.SocialApiId == "" {
		return 0, nil
	}

	return strconv.ParseInt(a.SocialApiId, 10, 64)
}

const SUPER_ADMIN_FLAG = "super-admin"

// HasFlag checks if the user has given flag
func (a *Account) HasFlag(flag string) bool {
	for _, f := range a.GlobalFlags {
		if f == flag {
			return true
		}
	}

	return false
}
