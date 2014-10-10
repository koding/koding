package models

import (
	"errors"

	// "fmt"
	"time"

	"github.com/koding/bongo"
)

type NotificationContent struct {
	// unique identifier of NotificationContent
	Id int64 `json:"id"`

	// target of the activity (replied messageId, followed accountId etc.)
	TargetId int64 `json:"targetId,string"   sql:"NOT NULL"`

	// Type of the NotificationContent
	TypeConstant string `json:"typeConstant" sql:"NOT NULL;TYPE:VARCHAR(100);"`

	// Creation date of the NotificationContent
	CreatedAt time.Time `json:"createdAt"`
}

const (
	// NotificationContent Types
	NotificationContent_TYPE_LIKE    = "like"
	NotificationContent_TYPE_COMMENT = "comment"
	NotificationContent_TYPE_MENTION = "mention"
	NotificationContent_TYPE_PM      = "pm"
)

func (n *NotificationContent) FindByTarget() error {
	s := map[string]interface{}{
		"type_constant": n.TypeConstant,
		"target_id":     n.TargetId,
	}
	q := bongo.NewQS(s)

	return n.One(q)
}

// CreateNotification validates notifiable instance and creates a new notification
// with actor activity.
func CreateNotificationContent(i Notifiable) (*NotificationContent, error) {
	// first check for type constant and target id
	if i.GetType() == "" {
		return nil, errors.New("Type must be set")
	}

	if i.GetTargetId() == 0 {
		return nil, errors.New("TargetId must be set")
	}

	if i.GetActorId() == 0 {
		return nil, errors.New("ActorId must be set")
	}

	// check for previous NotificationContent create if it does not exist (type:comment targetId:messageId)
	nc := NewNotificationContent()
	nc.TypeConstant = i.GetType()
	nc.TargetId = i.GetTargetId()

	if err := nc.Create(); err != nil {
		return nil, err
	}
	a := NewNotificationActivity()
	a.NotificationContentId = nc.Id
	a.ActorId = i.GetActorId()
	a.MessageId = i.GetMessageId()

	if err := a.Create(); err != nil {
		return nil, err
	}

	return nc, nil
}

// FetchByIds fetches notification contents with given ids
func (n *NotificationContent) FetchByIds(ids []int64) ([]NotificationContent, error) {
	notificationContents := make([]NotificationContent, 0)
	if err := bongo.B.FetchByIds(n, &notificationContents, ids); err != nil {
		return nil, err
	}
	return notificationContents, nil
}

// FetchMapByIds returns NotificationContent map with given ids
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

// CreateNotificationType creates an instance of notifiable subclasses
func CreateNotificationContentType(notificationType string) (Notifiable, error) {
	switch notificationType {
	case NotificationContent_TYPE_LIKE:
		return NewInteractionNotification(notificationType), nil
	case NotificationContent_TYPE_COMMENT:
		return NewReplyNotification(), nil
	case NotificationContent_TYPE_MENTION:
		return NewMentionNotification(), nil
	case NotificationContent_TYPE_PM:
		return NewPMNotification(), nil
	default:
		return nil, errors.New("undefined notification type")
	}

}

func (n *NotificationContent) GetContentType() (Notifiable, error) {
	return CreateNotificationContentType(n.TypeConstant)
}

func (n *NotificationContent) GetDefinition() string {
	nt, err := CreateNotificationContentType(n.TypeConstant)
	if err != nil {
		return ""
	}

	return nt.GetDefinition()
}
