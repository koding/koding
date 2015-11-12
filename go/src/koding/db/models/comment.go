package models

import (
	"labix.org/v2/mgo/bson"
	"time"
)

type Comment struct {
	Id              bson.ObjectId          `bson:"_id"`
	Body            string                 `bson:"body"`
	OriginType      string                 `bson:"originType"`
	OriginId        bson.ObjectId          `bson:"originId"`
	DeletedAt       time.Time              `bson:"deletedAt,omitempty"`
	Meta            Meta                   `bson:"meta"`
	IsLowQuality    bool                   `bson:"isLowQuality,omitempty"`
	DeletedBy       map[string]interface{} `bson:"deletedBy"`
	SocialMessageId int64                  `bson:"socialMessageId,omitempty"`
}
