package models

import (
	"errors"
	"fmt"
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
	NotificationContent_TYPE_LIKE     = "like"
	NotificationContent_TYPE_UPVOTE   = "upvote"
	NotificationContent_TYPE_DOWNVOTE = "downvote"
	NotificationContent_TYPE_COMMENT  = "comment"
	NotificationContent_TYPE_FOLLOW   = "follow"
	NotificationContent_TYPE_JOIN     = "join"
	NotificationContent_TYPE_LEFT     = "left"
)

type Notifiable interface {
	GetNotifiedUsers() ([]int64, error)
	GetType() string
	GetTargetId() int64
	FetchActors() ([]int64, int)
}

// it could be changed to interaction notification
type InteractionNotification struct {
	TargetId int64
	Type     string
}

func (n *InteractionNotification) GetNotifiedUsers() ([]int64, error) {
	i := NewInteraction()
	i.MessageId = n.TargetId
	return i.FetchInteractorIds()
}

func (n *InteractionNotification) GetType() string {
	return n.Type
}

func (n *InteractionNotification) GetTargetId() int64 {
	return n.TargetId
}

func (n *InteractionNotification) FetchActors() ([]int64, int) {

}

func NewInteractionNotification() *InteractionNotification {
	return &InteractionNotification{}
}

type ReplyNotification struct {
	TargetId int64
}

func (n *ReplyNotification) GetNotifiedUsers() ([]int64, error) {
	// fetch all repliers
	cm := NewChannelMessage()
	cm.Id = n.TargetId

	return cm.FetchReplierIds()
}

func (n *ReplyNotification) GetType() string {
	return NotificationContent_TYPE_COMMENT
}

func (n *ReplyNotification) GetTargetId() int64 {
	return n.TargetId
}

func (n *ReplyNotification) FetchActors() ([]int64, int) {

}

func NewReplyNotification() *ReplyNotification {
	return &ReplyNotification{}
}

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
func (n *NotificationContent) One(q *bongo.Query) error {
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
