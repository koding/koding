package models

import (
	"labix.org/v2/mgo/bson"
	"time"
)

type Rule struct {
	// To disable or enable current rule
	Enabled bool `bson:"enabled" json:"enabled"`

	// Behaviour of the rule, deny,allow or securepage
	Action string `bson:"mode" json:"mode"`

	// Applied filter (cross-query filled)
	Name string `bson:"name" json:"name"`
}

type Restriction struct {
	Id         bson.ObjectId `bson:"_id" json:"-"`
	DomainName string        `bson:"domainName" json:"domainName"`
	RuleList   []Rule        `bson:"ruleList" json:"ruleList"`
	CreatedAt  time.Time     `bson:"createdAt" json:"createdAt"`
	ModifiedAt time.Time     `bson:"modifiedAt" json:"modifiedAt"`
}
