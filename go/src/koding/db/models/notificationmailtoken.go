package models

import (
	"time"

	"labix.org/v2/mgo/bson"
)

type NotificationMailToken struct {
	ObjectId         bson.ObjectId `bson:"_id,omitempty"`
	NotificationType string        `bson:"notificationType"`
	UnsubscribeId    string        `bson:"unsubscribeId"`
	Recipient        bson.ObjectId `bson:"recipient"`
	CreatedAt        time.Time     `bson:"createdAt"`
}
