package models

import (
	"github.com/koding/bongo"
)

var (
	NOTIFIER_LIMIT = 2
)

type Notifiable interface {
	GetNotifiedUsers() ([]int64, error)
	GetType() string
	GetTargetId() int64
	FetchActors() (*ActorContainer, error)
	SetTargetId(int64)
}

type InteractionNotification struct {
	TargetId int64
	Type     string
}

func (n *InteractionNotification) GetNotifiedUsers() ([]int64, error) {
	i := NewInteraction()
	i.MessageId = n.TargetId
	return i.FetchInteractorIds(&bongo.Pagination{})
}

func (n *InteractionNotification) GetType() string {
	return n.Type
}

func (n *InteractionNotification) GetTargetId() int64 {
	return n.TargetId
}

func (n *InteractionNotification) SetTargetId(targetId int64) {
	n.TargetId = targetId
}

func (n *InteractionNotification) FetchActors() (*ActorContainer, error) {
	var count int
	i := NewInteraction()
	p := &bongo.Pagination{
		Limit: NOTIFIER_LIMIT,
	}
	i.MessageId = n.TargetId

	actors, err := i.FetchInteractorIdsWithCount(p, &count)
	if err != nil {
		return nil, err
	}

	ac := NewActorContainer()
	ac.LatestActors = actors
	ac.Count = count

	return ac, nil
}

func NewInteractionNotification(notificationType string) *InteractionNotification {
	return &InteractionNotification{Type: notificationType}
}

type ReplyNotification struct {
	TargetId int64
}

func (n *ReplyNotification) GetNotifiedUsers() ([]int64, error) {
	// fetch all repliers
	cm := NewChannelMessage()
	cm.Id = n.TargetId
	p := &bongo.Pagination{}
	replierIds, err := cm.FetchReplierIds(p, true)
}

func (n *ReplyNotification) GetType() string {
	return NotificationContent_TYPE_COMMENT
}

func (n *ReplyNotification) GetTargetId() int64 {
	return n.TargetId
}

func (n *ReplyNotification) SetTargetId(targetId int64) {
	n.TargetId = targetId
}

func (n *ReplyNotification) FetchActors() (*ActorContainer, error) {
	cm := NewChannelMessage()
	cm.Id = n.TargetId
	p := &bongo.Pagination{
		Limit: NOTIFIER_LIMIT,
	}
	var count int
	actors, err := cm.FetchReplierIdsWithCount(p, &count)
	if err != nil {
		return nil, err
	}

	ac := NewActorContainer()
	ac.LatestActors = actors
	ac.Count = count

	return ac, nil
}

func NewReplyNotification() *ReplyNotification {
	return &ReplyNotification{}
}
