package models

import (
	"errors"
	// "github.com/jinzhu/gorm"
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
	OwnerId      int64
}

func (n *InteractionNotification) GetNotifiedUsers(notificationContentId int64) ([]int64, error) {
	return fetchNotifiedUsers(notificationContentId)
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
	// filter obsolete activities and user's own activities
	actors := filterActors(naList, n.ListerId)

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
	// fetch all subscribers

	notifiees, err := fetchNotifiedUsers(notificationContentId)
	if err != nil {
		return nil, err
	}

	filteredNotifiees := make([]int64, 0)
	// append subscribed users and regress notifier
	for _, accountId := range notifiees {
		if accountId != n.NotifierId {
			filteredNotifiees = append(filteredNotifiees, accountId)
		}
	}

	return filteredNotifiees, nil
}

func fetchNotifiedUsers(contentId int64) ([]int64, error) {
	var notifiees []int64
	n := NewNotification()
	err := bongo.B.DB.Table(n.TableName()).
		Where("notification_content_id = ? AND subscribed_at > '1900-01-01'", contentId).
		Pluck("account_id", &notifiees).Error
	if err != nil {
		return nil, err
	}

	return notifiees, nil
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

	if len(naList) == 0 {
		return NewActorContainer(), nil
	}

	notification := NewNotification()
	notification.NotificationContentId = naList[0].NotificationContentId
	notification.AccountId = n.ListerId
	if err := notification.FetchByContent(); err != nil {
		return nil, err
	}

	if notification.UnsubscribedAt.Equal(ZeroDate()) {
		notification.UnsubscribedAt = time.Now()
	}

	actors := make([]int64, 0)
	actorMap := map[int64]struct{}{}
	for _, na := range naList {
		_, ok := actorMap[na.ActorId]
		if !ok && na.ActorId != n.ListerId && !na.Obsolete &&
			na.CreatedAt.After(notification.SubscribedAt) &&
			na.CreatedAt.Before(notification.UnsubscribedAt) {
			actors = append(actors, na.ActorId)
			actorMap[na.ActorId] = struct{}{}
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

func filterActors(naList []NotificationActivity, listerId int64) []int64 {
	actors := make([]int64, 0)
	for _, na := range naList {
		if !na.Obsolete && na.ActorId != listerId {
			actors = append(actors, na.ActorId)
		}
	}

	return actors
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

func (n *FollowNotification) FetchActors(naList []NotificationActivity) (*ActorContainer, error) {
	actors := filterActors(naList, n.ListerId)

	return prepareActorContainer(actors), nil
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
func (n *GroupNotification) FetchActors(naList []NotificationActivity) (*ActorContainer, error) {
	actors := filterActors(naList, n.ListerId)

	return prepareActorContainer(actors), nil
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
