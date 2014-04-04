package models

import (
	// "errors"
	// "fmt"
	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
)

type NotificationContent struct {
	Id int64 `json:"id"`
	// target of the activity (replied messageId, followed accountId etc.)
	TargetId int64  `json:"targetId"   sql:"NOT NULL"`
	Type     string `json:"type"       sql:"NOT NULL"`
}

const (
	NotificationContent_TYPE_LIKE    = "like"
	NotificationContent_TYPE_COMMENT = "comment"
	NotificationContent_TYPE_FOLLOW  = "follow"
	NotificationContent_TYPE_JOIN    = "join"
	NotificationContent_TYPE_LEFT    = "left"
)

func NewNotificationContent() *NotificationContent {
	return &NotificationContent{}
}

func (n *NotificationContent) GetId() int64 {
	return n.Id
}

func (n *NotificationContent) TableName() string {
	return "notification_content"
}

func (n *NotificationContent) Create() error {
	s := map[string]interface{}{
		"type":      n.Type,
		"target_id": n.TargetId,
	}

	if err := n.One(s); err != nil {
		if err != gorm.RecordNotFound {
			return err
		}
		return bongo.B.Create(n)
	}

	return nil
}

func (n *NotificationContent) One(selector map[string]interface{}) error {
	return bongo.B.One(n, n, selector)
}

func (n *NotificationContent) CreateByType(contentType string) error {
	// check for previous NotificationContent create if it does not exist (type:comment targetId:messageId)
	n.Type = contentType
	if err := n.Create(); err != nil {
		return err
	}

	replierIds, err := n.FetchMessageRepliers()
	if err != nil {
		return err
	}

	// TODO check subscribers/unsubscribers

	return n.NotifyUsers(replierIds)
}

func (n *NotificationContent) FetchMessageRepliers() ([]int64, error) {
	// fetch all repliers
	cm := NewChannelMessage()
	cm.Id = n.TargetId

	return cm.FetchReplierIds()
}

func (n *NotificationContent) NotifyUsers(recipients []int64) error {
	for i := 0; i < len(recipients); i++ {
		notification := NewNotification()
		notification.AccountId = recipients[i]
		notification.NotificationContentId = n.Id
		// TODO instead of interrupting the call send error messages to a queue
		if err := notification.Create(); err != nil {
			return err
		}
	}

	return nil
}
