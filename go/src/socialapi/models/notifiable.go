package models

import (
	"errors"
	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
	"time"
)

var (
	NOTIFIER_LIMIT = 3
)

type Notifiable interface {
	// users that will be notified are fetched while creating notification
	GetNotifiedUsers(notificationContentId int64) ([]int64, error)
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

func (n *InteractionNotification) GetNotifiedUsers(notificationContentId int64) ([]int64, error) {
	i := NewInteraction()
	i.MessageId = n.TargetId

	// fetch message owner
	targetMessage := NewChannelMessage()
	if err := targetMessage.ById(n.TargetId); err != nil {
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
	p := bongo.NewPagination(NOTIFIER_LIMIT, 0)
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

func (n *ReplyNotification) GetNotifiedUsers(notificationContentId int64) ([]int64, error) {
	// fetch all repliers
	cm := NewChannelMessage()
	cm.Id = n.TargetId

	p := &bongo.Pagination{}
	replierIds, err := cm.FetchReplierIds(p, true, time.Time{})
	if err != nil {
		return nil, err
	}
	repliersMap := map[int64]struct{}{}
	for _, replierId := range replierIds {
		repliersMap[replierId] = struct{}{}
	}

	var subscribers []NotificationSubscription
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"notification_content_id": notificationContentId,
		},
	}
	ns := NewNotificationSubscription()
	if err := ns.Some(&subscribers, q); err != nil {
		return nil, err
	}

	// regress unsubscribed users and append subscribed ones
	for _, subscriber := range subscribers {
		switch subscriber.TypeConstant {
		case NotificationSubscription_TYPE_SUBSCRIBE:
			repliersMap[subscriber.AccountId] = struct{}{}
		case NotificationSubscription_TYPE_UNSUBSCRIBE:
			delete(repliersMap, subscriber.AccountId)
		}
	}

	// regress notifier from notified users
	delete(repliersMap, n.NotifierId)

	filteredRepliers := make([]int64, 0)
	for replierId, _ := range repliersMap {
		filteredRepliers = append(filteredRepliers, replierId)
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

// Fetch Actors retrieves latest actors. For message repliers, if first checks
// users first reply message. And also fetches user's subscription status.
// if user both replied and subscribed to a message then gets the event's time
// that has first occurred.
func (n *ReplyNotification) FetchActors() (*ActorContainer, error) {
	if n.TargetId == 0 {
		return nil, errors.New("TargetId is not set")
	}

	// first determine message owner
	channelMessage := NewChannelMessage()
	if err := channelMessage.ById(n.TargetId); err != nil {
		return nil, err
	}

	// if lister is message owner than lower time limit for fetching repliers
	// will be messages creation date
	timeLimit := channelMessage.CreatedAt
	// if lister is not message owner than check listers first replied message.
	if channelMessage.AccountId != n.ListerId {
		mr := NewMessageReply()
		mr.MessageId = n.TargetId

		// we are gonna fetch actors starting from user's first reply
		if err := mr.FetchFirstAccountReply(n.ListerId); err != nil {
			return nil, err
		}

		// lower limit is lister's first reply message
		if !mr.CreatedAt.IsZero() {
			timeLimit = mr.CreatedAt
		}
	}

	// TODO make it async
	// check if user is already subscribed to / unsubscribed from target
	nc := NewNotificationContent()
	nc.TargetId = n.TargetId
	nc.TypeConstant = NotificationContent_TYPE_COMMENT
	ns := NewNotificationSubscription()
	ns.AccountId = n.ListerId
	var err error
	if err = ns.FetchByNotificationContent(nc); err != nil {
		if err != gorm.RecordNotFound {
			return nil, err
		}
	}

	lowerTimeLimit := true
	if err != gorm.RecordNotFound {
		// if unsubscription happens then fetch all notifications till
		// the unsubscription date
		if ns.TypeConstant == NotificationSubscription_TYPE_UNSUBSCRIBE {
			lowerTimeLimit = false
		}

		//
		timeLimit = ns.AddedAt
	}

	cm := NewChannelMessage()
	cm.Id = n.TargetId
	cm.AccountId = n.ListerId

	p := &bongo.Pagination{
		Limit: NOTIFIER_LIMIT,
	}

	// for preparing Actor Container we need latest actors and total replier count
	var count int
	actors, err := cm.FetchReplierIdsWithCount(p, &count, timeLimit, lowerTimeLimit)
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

func (n *FollowNotification) GetNotifiedUsers(notificationContentId int64) ([]int64, error) {
	users := make([]int64, 0)
	return append(users, n.TargetId), nil
}

func (n *FollowNotification) GetType() string {
	return NotificationContent_TYPE_FOLLOW
}

func (n *FollowNotification) GetTargetId() int64 {
	return n.TargetId
}

func (n *FollowNotification) FetchActors([]NotificationActivity) (*ActorContainer, error) {
	if n.TargetId == 0 {
		return nil, errors.New("TargetId is not set")
	}

	ac := NewActorContainer()

	// a := NewNotificationActivity()
	// // a.TargetId = n.TargetId
	// // a.TypeConstant = NotificationContent_TYPE_FOLLOW
	// actorIds, err := a.FetchActorIds(NOTIFIER_LIMIT)
	// if err != nil {
	// 	return nil, err
	// }

	// ac.LatestActors = actorIds
	// ac.Count = len(ac.LatestActors) // TODO count also must be retrieved

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
func (n *GroupNotification) GetNotifiedUsers(notificationContentId int64) ([]int64, error) {
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
func (n *GroupNotification) FetchActors([]NotificationActivity) (*ActorContainer, error) {
	// a := NewNotificationActivity()
	// a.TargetId = n.TargetId
	// a.TypeConstant = n.TypeConstant
	// actors, err := a.FetchActorIds(NOTIFIER_LIMIT)
	// if err != nil {
	// 	return nil, err
	// }

	ac := NewActorContainer()
	// ac.LatestActors = actors
	// ac.Count = len(actors)

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
