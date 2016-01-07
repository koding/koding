package models

import (
	"time"

	"gopkg.in/mgo.v2/bson"
)

type NotificationMailToken struct {
	ObjectId         bson.ObjectId `bson:"_id,omitempty"`
	NotificationType string        `bson:"notificationType"`
	UnsubscribeId    string        `bson:"unsubscribeId"`
	Recipient        bson.ObjectId `bson:"recipient"`
	CreatedAt        time.Time     `bson:"createdAt"`
}
