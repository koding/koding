package models

import (
	"time"

	"github.com/koding/bongo"
)

func (a *NotificationActivity) BeforeCreate() {
	a.CreatedAt = time.Now()
}

func (a *NotificationActivity) BeforeUpdate() {
	a.Obsolete = true
}

func (a *NotificationActivity) GetId() int64 {
	return a.Id
}

func NewNotificationActivity() *NotificationActivity {
	return &NotificationActivity{}
}

func (a NotificationActivity) TableName() string {
	return "notification.notification_activity"
}

func (a *NotificationActivity) One(q *bongo.Query) error {
	return bongo.B.One(a, a, q)
}

func (a *NotificationActivity) Some(data interface{}, q *bongo.Query) error {

	return bongo.B.Some(a, data, q)
}

func (a *NotificationActivity) ById(id int64) error {
	return bongo.B.ById(a, id)
}
