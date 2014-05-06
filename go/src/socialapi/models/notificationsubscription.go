package models

import (
	"errors"
	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
	"time"
)

type NotificationSubscription struct {
	Id                    int64
	AccountId             int64
	NotificationContentId int64
	TypeConstant          string // subscribe/unsubscribe
	AddedAt               time.Time
}

const (
	NotificationSubscription_TYPE_SUBSCRIBE   = "subscribe"
	NotificationSubscription_TYPE_UNSUBSCRIBE = "unsubscribe"
)

func (ns *NotificationSubscription) GetId() int64 {
	return ns.Id
}

func (ns NotificationSubscription) TableName() string {
	return "api.notification_subscription"
}

func NewNotificationSubscription() *NotificationSubscription {
	return &NotificationSubscription{}
}

// SubscribeMessage subscribes/unsubscribes a given account to/from message
// given with targetId
func SubscribeMessage(accountId, targetId int64, typeConstant string) error {
	if accountId == 0 {
		return errors.New("Account Id must be set")
	}

	nc := NewNotificationContent()
	nc.TargetId = targetId
	nc.TypeConstant = NotificationContent_TYPE_COMMENT
	// create notification content if it does not exist
	if err := nc.Create(); err != nil {
		return err
	}

	ns := NewNotificationSubscription()
	ns.AccountId = accountId
	ns.NotificationContentId = nc.Id
	ns.TypeConstant = typeConstant

	return ns.Create()
}

func (ns *NotificationSubscription) Create() error {
	s := map[string]interface{}{
		"notification_content_id": ns.NotificationContentId,
		"account_id":              ns.AccountId,
	}
	typeConstant := ns.TypeConstant
	q := bongo.NewQS(s)
	if err := ns.One(q); err != nil {
		if err != gorm.RecordNotFound {
			return err
		}

		return bongo.B.Create(ns)
	}

	if ns.TypeConstant != typeConstant {
		ns.TypeConstant = typeConstant
		return bongo.B.Update(ns)
	}

	return nil
}

//
func (ns *NotificationSubscription) FetchByNotificationContent(nc *NotificationContent) error {
	s := map[string]interface{}{
		"target_id":     nc.TargetId,
		"type_constant": nc.TypeConstant,
	}
	q := bongo.NewQS(s)
	if err := nc.One(q); err != nil {
		return err
	}

	s = map[string]interface{}{
		"account_id":              ns.AccountId,
		"notification_content_id": nc.Id,
	}
	q = bongo.NewQS(s)

	return ns.One(q)
}

func (ns *NotificationSubscription) One(q *bongo.Query) error {

	return bongo.B.One(ns, ns, q)
}

func (ns *NotificationSubscription) Some(data interface{}, q *bongo.Query) error {

	return bongo.B.Some(ns, data, q)
}

func (ns *NotificationSubscription) BeforeCreate() {
	ns.AddedAt = time.Now()
}

func (ns *NotificationSubscription) BeforeUpdate() {
	ns.AddedAt = time.Now()
}

func (ns *NotificationSubscription) AfterCreate() {
	bongo.B.AfterCreate(ns)
}

func (ns *NotificationSubscription) AfterUpdate() {
	bongo.B.AfterUpdate(ns)
}

func (ns *NotificationSubscription) AfterDelete() {
	bongo.B.AfterDelete(ns)
}
