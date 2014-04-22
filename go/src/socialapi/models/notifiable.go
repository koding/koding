package models

import (
	"errors"
	"github.com/koding/bongo"
	"time"
)

var (
	NOTIFIER_LIMIT = 3
)

type Notifiable interface {
	// users that will be notified are fetched while creating notification
	GetNotifiedUsers() ([]int64, error)
	GetType() string
	GetTargetId() int64
	FetchActors() (*ActorContainer, error)
	SetTargetId(int64)
	SetListerId(int64)
}

type InteractionNotification struct {
	TargetId     int64
	TypeConstant string
	ListerId     int64
	NotifierId   int64
}

func (n *InteractionNotification) GetNotifiedUsers() ([]int64, error) {
	i := NewInteraction()
	i.MessageId = n.TargetId

	// fetch message owner
	targetMessage := NewChannelMessage()
	targetMessage.Id = n.TargetId
	if err := targetMessage.Fetch(); err != nil {
		return nil, err
	}

	notifiedUsers := make([]int64, 0)
	// notify just the owner
	if targetMessage.AccountId != n.NotifierId {
		notifiedUsers = append(notifiedUsers, targetMessage.AccountId)
	}

	return notifiedUsers, nil
}

func (n *InteractionNotification) GetType() string {
	return n.TypeConstant
}

func (n *InteractionNotification) GetTargetId() int64 {
	return n.TargetId
}

func (n *InteractionNotification) SetTargetId(targetId int64) {
	n.TargetId = targetId
}

func (n *InteractionNotification) FetchActors() (*ActorContainer, error) {
	if n.TargetId == 0 {
		return nil, errors.New("TargetId is not set")
	}

	i := NewInteraction()
	p := &bongo.Pagination{
		Limit: NOTIFIER_LIMIT,
	}
	i.MessageId = n.TargetId

	actors, err := i.FetchInteractorIds(n.GetType(), p)
	if err != nil {
		return nil, err
	}

	ac := NewActorContainer()
	ac.LatestActors = actors
	ac.Count, err = i.FetchInteractorCount()
	if err != nil {
		return nil, err
	}

	return ac, nil
}

func (n *InteractionNotification) SetListerId(listerId int64) {
	n.ListerId = listerId
}

func NewInteractionNotification(notificationType string) *InteractionNotification {
	return &InteractionNotification{TypeConstant: notificationType}
}

type ReplyNotification struct {
	TargetId   int64
	ListerId   int64
	NotifierId int64
}

func (n *ReplyNotification) GetNotifiedUsers() ([]int64, error) {
	// fetch all repliers
	cm := NewChannelMessage()
	cm.Id = n.TargetId

	p := &bongo.Pagination{}
	replierIds, err := cm.FetchReplierIds(p, true, time.Time{})

	if err != nil {
		return nil, err
	}

	// regress notifier from notified users
	filteredRepliers := make([]int64, 0)
	for _, replierId := range replierIds {
		if replierId != n.NotifierId {
			filteredRepliers = append(filteredRepliers, replierId)
		}
	}

	return filteredRepliers, nil
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
	if n.TargetId == 0 {
		return nil, errors.New("TargetId is not set")
	}

	mr := NewMessageReply()
	mr.MessageId = n.TargetId

	// we are gonna fetch actors after notified users first reply
	if err := mr.FetchFirstAccountReply(n.ListerId); err != nil {
		return nil, err
	}

	cm := NewChannelMessage()
	cm.Id = n.TargetId
	cm.AccountId = n.ListerId

	p := &bongo.Pagination{
		Limit: NOTIFIER_LIMIT,
	}

	// for preparing Actor Container we need latest actors and total replier count
	var count int
	actors, err := cm.FetchReplierIdsWithCount(p, &count, mr.CreatedAt)
	if err != nil {
		return nil, err
	}

	ac := NewActorContainer()
	ac.LatestActors = actors
	ac.Count = count

	return ac, nil
}

func (n *ReplyNotification) SetListerId(listerId int64) {
	n.ListerId = listerId
}

func NewReplyNotification() *ReplyNotification {
	return &ReplyNotification{}
}

type FollowNotification struct {
	// followed account
	TargetId int64
	ListerId int64
	// follower account
	NotifierId int64
}

func (n *FollowNotification) GetNotifiedUsers() ([]int64, error) {
	users := make([]int64, 0)
	return append(users, n.TargetId), nil
}

func (n *FollowNotification) GetType() string {
	return NotificationContent_TYPE_FOLLOW
}

func (n *FollowNotification) GetTargetId() int64 {
	return n.TargetId
}

func (n *FollowNotification) FetchActors() (*ActorContainer, error) {
	if n.TargetId == 0 {
		return nil, errors.New("TargetId is not set")
	}

	ac := NewActorContainer()

	a := NewActivity()
	a.TargetId = n.TargetId
	a.TypeConstant = NotificationContent_TYPE_FOLLOW
	actorIds, err := a.FetchActorIds()
	if err != nil {
		return nil, err
	}

	ac.LatestActors = actorIds
	ac.Count = len(ac.LatestActors)

	return ac, nil
}

func (n *FollowNotification) SetTargetId(targetId int64) {
	n.TargetId = targetId
}

func (n *FollowNotification) SetListerId(listerId int64) {
	n.ListerId = listerId
}

func NewFollowNotification() *FollowNotification {
	return &FollowNotification{}
}

type GroupNotification struct {
	TargetId     int64
	ListerId     int64
	OwnerId      int64
	NotifierId   int64
	TypeConstant string
	Admins       []int64
}

// fetch group admins
func (n *GroupNotification) GetNotifiedUsers() ([]int64, error) {
	if len(n.Admins) == 0 {
		return nil, errors.New("admins cannot be empty")
	}

	return n.Admins, nil
}

func (n *GroupNotification) GetType() string {
	return n.TypeConstant
}

func (n *GroupNotification) GetTargetId() int64 {
	return n.TargetId
}

// fetch notifiers
func (n *GroupNotification) FetchActors() (*ActorContainer, error) {
	a := NewActivity()
	a.TargetId = n.TargetId
	a.TypeConstant = n.TypeConstant
	actors, err := a.FetchActorIds()
	if err != nil {
		return nil, err
	}

	ac := NewActorContainer()
	ac.LatestActors = actors
	ac.Count = len(actors)

	return ac, nil
}

func (n *GroupNotification) SetTargetId(targetId int64) {
	n.TargetId = targetId
}

func (n *GroupNotification) SetListerId(listerId int64) {
	n.ListerId = listerId
}

func NewGroupNotification(typeConstant string) *GroupNotification {
	return &GroupNotification{TypeConstant: typeConstant}
}
