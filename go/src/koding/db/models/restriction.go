package models

import (
	"labix.org/v2/mgo/bson"
	"time"
)

type Restriction struct {
	Id         bson.ObjectId   `bson:"_id" json:"-"`
	DomainName string          `bson:"domainName" json:"domainName"`
	Filters    []bson.ObjectId `bson:"filters" json:"filters"`
	CreatedAt  time.Time       `bson:"createdAt" json:"createdAt"`
	ModifiedAt time.Time       `bson:"modifiedAt" json:"modifiedAt"`
}
