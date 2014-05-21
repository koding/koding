package models

import (
	"labix.org/v2/mgo/bson"
)

type NotificationMailToken struct {
	NotificationType string        `bson:"notificationType"`
	UnsubscribeId    string        `bson:"unsubscribeId"`
	Recipient        bson.ObjectId `bson:"recipient"`
}
