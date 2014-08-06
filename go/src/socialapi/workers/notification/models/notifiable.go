package models

import (
	"math"

	"github.com/koding/bongo"
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
	SetActorId(int64)
	// used for notification emails
	GetDefinition() string
	// used for notification emails
	GetActivity() string
}

func fetchNotifiedUsers(contentId int64) ([]int64, error) {
	var notifiees []int64
	n := NewNotification()
	query := bongo.B.DB.Table(n.TableName())
	query = query.Where("notification_content_id = ?", contentId)
	query = query.Where("subscribed_at > ?", ZeroDate())
	query = query.Where("unsubscribed_at = ?", ZeroDate())

	if err := query.Pluck("account_id", &notifiees).Error; err != nil {
		return nil, err
	}

	return notifiees, nil
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
