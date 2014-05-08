package models

import (
	"errors"
	// "github.com/jinzhu/gorm"
	// "fmt"
	"github.com/koding/bongo"
	"math"
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
	FetchActors([]NotificationActivity) (*ActorContainer, error)
	SetTargetId(int64)
	SetListerId(int64)
	GetActorId() int64
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

func (n *InteractionNotification) FetchActors(naList []NotificationActivity) (*ActorContainer, error) {
	if n.TargetId == 0 {
		return nil, errors.New("TargetId is not set")
	}

	// TODO user should not be notified if she interacts with her own message
	actors := make([]int64, 0)
	for _, na := range naList {
		if !na.Obsolete {
			actors = append(actors, na.ActorId)
		}
	}

	return prepareActorContainer(actors), nil
}

func (n *InteractionNotification) SetListerId(listerId int64) {
	n.ListerId = listerId
}

func (n *InteractionNotification) GetActorId() int64 {
	return n.NotifierId
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

func (n *ReplyNotification) FetchActors(naList []NotificationActivity) (*ActorContainer, error) {
	if n.TargetId == 0 {
		return nil, errors.New("TargetId is not set")
	}
	// TODO inject this information
	// first determine message owner
	channelMessage := NewChannelMessage()
	if err := channelMessage.ById(n.TargetId); err != nil {
		return nil, err
	}

	found := false
	if channelMessage.AccountId == n.ListerId {
		found = true
	}

	actors := make([]int64, 0)
	actorMap := map[int64]struct{}{}
	for _, na := range naList {
		_, ok := actorMap[na.ActorId]
		if found && !ok && na.ActorId != n.ListerId && !na.Obsolete {
			actors = append(actors, na.ActorId)
			actorMap[na.ActorId] = struct{}{}
		}

		if na.ActorId == n.ListerId {
			found = true
		}
	}

	return prepareActorContainer(actors), nil
}

func reverse(ids []int64) []int64 {
	for i, j := 0, len(ids)-1; i < j; i, j = i+1, j-1 {
		ids[i], ids[j] = ids[j], ids[i]
	}

	return ids
}

func prepareActorContainer(actors []int64) *ActorContainer {
	actors = reverse(actors)
	actorLength := len(actors)
	actorLimit := int(math.Min(float64(actorLength), float64(NOTIFIER_LIMIT)))

	ac := NewActorContainer()
	ac.LatestActors = actors[0:actorLimit]
	ac.Count = actorLength

	return ac
}

func (n *ReplyNotification) SetListerId(listerId int64) {
	n.ListerId = listerId
}

func (n *ReplyNotification) GetActorId() int64 {
	return n.NotifierId
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

func (n *FollowNotification) GetActorId() int64 {
	return n.NotifierId
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

func (n *GroupNotification) GetActorId() int64 {
	return n.NotifierId
}

func NewGroupNotification(typeConstant string) *GroupNotification {
	return &GroupNotification{TypeConstant: typeConstant}
}
