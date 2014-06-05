package models

import (
	"time"
)

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

func (n *ReplyNotification) SetListerId(listerId int64) {
	n.ListerId = listerId
}

func (n *ReplyNotification) GetActorId() int64 {
	return n.NotifierId
}

func (n *ReplyNotification) SetActorId(actorId int64) {
	n.NotifierId = actorId
}

func NewReplyNotification() *ReplyNotification {
	return &ReplyNotification{}
}

func (n *ReplyNotification) GetDefinition() string {
	return getGenericDefinition(NotificationContent_TYPE_COMMENT)
}

func (n *ReplyNotification) GetActivity() string {
	if n.ListerId == n.NotifierId {
		return "commented on your"
	}

	return "also commented on"
}
