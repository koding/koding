package models

import (
	"errors"
	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
	"time"
)

type NotificationContent struct {
	Id int64 `json:"id"`
	// target of the activity (replied messageId, followed accountId etc.)
	TargetId     int64     `json:"targetId"   sql:"NOT NULL"`
	TypeConstant string    `json:"typeConstant"       sql:"NOT NULL"`
	CreatedAt    time.Time `json:"createdAt"`
}

const (
	NotificationContent_TYPE_LIKE     = "like"
	NotificationContent_TYPE_UPVOTE   = "upvote"
	NotificationContent_TYPE_DOWNVOTE = "downvote"
	NotificationContent_TYPE_COMMENT  = "comment"
	NotificationContent_TYPE_FOLLOW   = "follow"
	NotificationContent_TYPE_JOIN     = "join"
	NotificationContent_TYPE_LEAVE    = "leave"
)

func NewNotificationContent() *NotificationContent {
	return &NotificationContent{}
}

func (n *NotificationContent) GetId() int64 {
	return n.Id
}

func (n NotificationContent) TableName() string {
	return "api.notification_content"
}

func (n *NotificationContent) Create() error {
	s := map[string]interface{}{
		"type_constant": n.TypeConstant,
		"target_id":     n.TargetId,
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

func (n *NotificationContent) ById(id int64) error {
	return bongo.B.ById(n, id)
}

func CreateNotification(i Notifiable) error {
	// check for previous NotificationContent create if it does not exist (type:comment targetId:messageId)
	n := NewNotificationContent()
	n.TypeConstant = i.GetType()
	if n.TypeConstant == "" {
		return errors.New("Type must be set")
	}

	n.TargetId = i.GetTargetId()
	if n.TargetId == 0 {
		return errors.New("TargetId must be set")
	}

	if err := n.Create(); err != nil {
		return err
	}

	// fetch users and updates their cache if it is available
	replierIds, err := i.GetNotifiedUsers()
	if err != nil {
		return err
	}

	// TODO check subscribers/unsubscribers

	return n.NotifyUsers(replierIds)
}

func (n *NotificationContent) NotifyUsers(recipients []int64) {
	for i := 0; i < len(recipients); i++ {
		notification := NewNotification()
		notification.AccountId = recipients[i]
		notification.NotificationContentId = n.Id
		if err := notification.Create(); err != nil {
			if Log != nil {
				Log.Error("An error occurred while notifying user %d: %s", notification.AccountId, err.Error())
			}
		}
	}
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
	if err != nil {
		return nil, err
	}

	ncMap := make(map[int64]NotificationContent, 0)
	for _, nc := range ncList {
		ncMap[nc.Id] = nc
	}

	return ncMap, nil
}

func (n *NotificationContent) GetEventType() string {
	switch n.TypeConstant {
	case NotificationContent_TYPE_LIKE:
		return "LikeIsAdded"
	case NotificationContent_TYPE_COMMENT:
		return "ReplyIsAdded"
	case NotificationContent_TYPE_FOLLOW:
		return "FollowHappened"
	case NotificationContent_TYPE_JOIN:
		return "GroupJoined"
	case NotificationContent_TYPE_LEAVE:
		return "GroupLeft"
	default:
		return "undefined"
	}
}

func CreateNotificationType(notificationType string) (Notifiable, error) {
	switch notificationType {
	case "like":
		return NewInteractionNotification(notificationType), nil
	case "comment":
		return NewReplyNotification(), nil
	case "follow":
		return NewFollowNotification(), nil
	case "join":
		return NewGroupNotification(notificationType), nil
	case "leave":
		return NewGroupNotification(notificationType), nil
	default:
		return nil, errors.New("undefined notification type")
	}

}

func (nc *NotificationContent) AfterCreate() {
	bongo.B.AfterCreate(nc)
}

func (nc *NotificationContent) AfterUpdate() {
	bongo.B.AfterUpdate(nc)
}

func (nc *NotificationContent) AfterDelete() {
	bongo.B.AfterDelete(nc)
}
