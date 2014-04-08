package models

import (
	"errors"
	"fmt"
	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
	"time"
)

type NotificationContent struct {
	Id int64 `json:"id"`
	// target of the activity (replied messageId, followed accountId etc.)
	TargetId  int64  `json:"targetId"   sql:"NOT NULL"`
	Type      string `json:"type"       sql:"NOT NULL"`
	CreatedAt time.Time
}

const (
	NotificationContent_TYPE_LIKE     = "like"
	NotificationContent_TYPE_UPVOTE   = "upvote"
	NotificationContent_TYPE_DOWNVOTE = "downvote"
	NotificationContent_TYPE_COMMENT  = "comment"
	NotificationContent_TYPE_FOLLOW   = "follow"
	NotificationContent_TYPE_JOIN     = "join"
	NotificationContent_TYPE_LEFT     = "left"
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
	q := bongo.NewQS(s)
	if err := n.One(q); err != nil {
		if err != gorm.RecordNotFound {
			return err
		}
		return bongo.B.Create(n)
	}

	return nil
}

func (n *NotificationContent) One(q *bongo.Query) error {
	return bongo.B.One(n, n, q)
}

func CreateNotification(i Notifiable) error {
	// check for previous NotificationContent create if it does not exist (type:comment targetId:messageId)
	n := NewNotificationContent()
	n.Type = i.GetType()
	if n.Type == "" {
		return errors.New("Type must be set")
	}

	n.TargetId = i.GetTargetId()
	if n.TargetId == 0 {
		return errors.New("TargetId must be set")
	}

	if err := n.Create(); err != nil {
		return err
	}

	replierIds, err := i.GetNotifiedUsers()
	if err != nil {
		return err
	}

	// TODO check subscribers/unsubscribers

	return n.NotifyUsers(replierIds)
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

func (n *NotificationContent) FetchByIds(ids []int64) ([]NotificationContent, error) {
	notificationContents := make([]NotificationContent, 0)
	if err := bongo.B.FetchByIds(n, &notificationContents, ids); err != nil {
		return nil, err
	}
	return notificationContents, nil
}

func (n *NotificationContent) FetchMapByIds(ids []int64) (map[int64]NotificationContent, error) {
	ncList, err := n.FetchByIds(ids)
	fmt.Printf("content liste : %v", ncList)
	if err != nil {
		return nil, err
	}

	ncMap := make(map[int64]NotificationContent, 0)
	for _, nc := range ncList {

		ncMap[nc.Id] = nc
	}
	fmt.Printf("map: %+v", ncMap)
	return ncMap, nil
}

func CreateNotificationType(notificationType string) (Notifiable, error) {
	switch notificationType {
	case "like":
		return NewInteractionNotification(notificationType), nil
	case "comment":
		return NewReplyNotification(), nil
	default:
		return nil, errors.New("undefined notification type")
	}

}
