package models

import (
	// "errors"
	// "fmt"
	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
)

type Notification struct {
	Id int64 `json:"id"`
	// target of the activity (replied messageId, followed accountId etc.)
	TargetId int64  `json:"targetId"   sql:"NOT NULL"`
	Type     string `json:"type"       sql:"NOT NULL"`
}

const (
	Notification_TYPE_LIKE    = "like"
	Notification_TYPE_COMMENT = "comment"
	Notification_TYPE_FOLLOW  = "follow"
	Notification_TYPE_JOIN    = "join"
	Notification_TYPE_LEFT    = "left"
)

func NewNotification() *Notification {
	return &Notification{}
}

func (n *Notification) GetId() int64 {
	return n.Id
}

func (n *Notification) TableName() string {
	return "notification"
}

func (n *Notification) Create() error {
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

func (n *Notification) One(selector map[string]interface{}) error {
	return bongo.B.One(n, n, selector)
}

func (n *Notification) CreateByType(notificationType string) error {
	// check for previous notification create if it does not exist (type:comment targetId:messageId)
	n.Type = notificationType
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

func (n *Notification) FetchMessageRepliers() ([]int64, error) {
	// fetch all repliers
	cm := NewChannelMessage()
	cm.Id = n.TargetId
	return cm.FetchRepliers()
}

func (n *Notification) NotifyUsers(notifiees []int64) error {
	for i := 0; i < len(notifiees); i++ {
		notifiee := NewNotifiee()
		notifiee.AccountId = notifiees[i]
		notifiee.NotificationId = n.Id
		if err := notifiee.Create(); err != nil {
			return err
		}
	}
	return nil
}
