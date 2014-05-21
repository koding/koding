package models

import (
	"errors"
	// "fmt"
	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
	"time"
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
	NotificationContent_TYPE_FOLLOW  = "follow"
	NotificationContent_TYPE_JOIN    = "join"
	NotificationContent_TYPE_LEAVE   = "leave"
	NotificationContent_TYPE_MENTION = "mention"
)

func NewNotificationContent() *NotificationContent {
	return &NotificationContent{}
}

func (n *NotificationContent) GetId() int64 {
	return n.Id
}

func (n NotificationContent) TableName() string {
	return "notification.notification_content"
}

// Create checks for NotificationContent using type_constant and target_id
// and creates new one if it does not exist.
func (n *NotificationContent) Create() error {
	if err := n.FindByTarget(); err != nil {
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
	case NotificationContent_TYPE_FOLLOW:
		return NewFollowNotification(), nil
	case NotificationContent_TYPE_JOIN:
		return NewGroupNotification(notificationType), nil
	case NotificationContent_TYPE_LEAVE:
		return NewGroupNotification(notificationType), nil
	case NotificationContent_TYPE_MENTION:
		return NewMentionNotification(), nil
	default:
		return nil, errors.New("undefined notification type")
	}

}

func (n *NotificationContent) GetContentType() (Notifiable, error) {
	return CreateNotificationContentType(n.TypeConstant)
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
