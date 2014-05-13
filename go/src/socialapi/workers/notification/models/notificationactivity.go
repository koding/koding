package models

import (
	// "fmt"
	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
	"time"
)

// NotificationActivity stores each user NotificationActivity related to notification content.
// When a user makes duplicate NotificationActivity for the same content
// old one is set as obsolete and new one is added to NotificationActivity table
type NotificationActivity struct {
	// unique identifier of NotificationActivity
	Id int64 `json:"id"`

	// notification content foreign key
	NotificationContentId int64 `json:"notificationContentId" sql:"NOT NULL"`

	// notifier account foreign key
	ActorId int64 `json:"actorId" sql:"NOT NULL"`

	// activity creation time
	CreatedAt time.Time `json:"createdAt" sql:"NOT NULL"`

	// activity obsolete information
	Obsolete bool `json:"obsolete" sql:"NOT NULL"`
}

func (a *NotificationActivity) GetId() int64 {
	return a.Id
}

func NewNotificationActivity() *NotificationActivity {
	return &NotificationActivity{}
}

func (a NotificationActivity) TableName() string {
	return "notification.notification_activity"
}

func (a *NotificationActivity) Create() error {
	s := map[string]interface{}{
		"notification_content_id": a.NotificationContentId,
		"actor_id":                a.ActorId,
	}

	q := bongo.NewQS(s)
	found := true
	if err := a.One(q); err != nil {
		if err != gorm.RecordNotFound {
			return err
		}
		found = false
	}

	if found {
		if err := bongo.B.Update(a); err != nil {
			return err
		}
		a.Id = 0
		a.Obsolete = false
	}

	return bongo.B.Create(a)
}

func (a *NotificationActivity) BeforeCreate() {
	a.CreatedAt = time.Now()
}

func (a *NotificationActivity) BeforeUpdate() {
	a.Obsolete = true
}

func (a *NotificationActivity) FetchByContentIds(ids []int64) ([]NotificationActivity, error) {
	activities := make([]NotificationActivity, 0)
	err := bongo.B.DB.Table(a.TableName()).
		Where("notification_content_id IN (?)", ids).
		Order("id asc").
		Find(&activities).Error

	if err != nil {
		return nil, err
	}

	return activities, nil
}

func (a *NotificationActivity) FetchMapByContentIds(ids []int64) (map[int64][]NotificationActivity, error) {
	aMap := make(map[int64][]NotificationActivity, 0)
	if len(ids) == 0 {
		return aMap, nil
	}
	aList, err := a.FetchByContentIds(ids)
	if err != nil {
		return nil, err
	}

	for _, activity := range aList {
		aMap[activity.NotificationContentId] = append(aMap[activity.NotificationContentId], activity)
	}

	return aMap, nil
}

func (a *NotificationActivity) Fetch() error {

	return bongo.B.Fetch(a)
}

func (a *NotificationActivity) One(q *bongo.Query) error {

	return bongo.B.One(a, a, q)
}

func (a *NotificationActivity) Some(data interface{}, q *bongo.Query) error {

	return bongo.B.Some(a, data, q)
}
