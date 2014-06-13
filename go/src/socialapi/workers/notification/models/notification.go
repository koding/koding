package models

import (
	"encoding/json"
	"errors"
	// "fmt"
	"socialapi/models"
	"time"

	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
)

type Notification struct {
	// unique identifier of Notification
	Id int64 `json:"id"`

	// notification recipient account id
	AccountId int64 `json:"accountId,string" sql:"NOT NULL"`

	// notification content foreign key
	NotificationContentId int64 `json:"notificationContentId" sql:"NOT NULL"`

	// glanced information
	Glanced bool `json:"glanced" sql:"NOT NULL"`

	// last notifier addition time. when user first subscribes it is set to ZeroDate
	ActivatedAt time.Time `json:"activatedAt"`

	// user's subscription time to related content
	SubscribedAt time.Time `json:"subscribedAt"`

	// notification type as subscribed/unsubscribed
	UnsubscribedAt time.Time `json:"unsubscribedAt"`

	SubscribeOnly bool `json:"-" sql:"-"`
}

func (n *Notification) BeforeCreate() {
	if n.UnsubscribedAt.IsZero() && n.SubscribedAt.IsZero() {
		n.SubscribedAt = time.Now()
	}
}

func (n *Notification) BeforeUpdate() {
	if n.UnsubscribedAt.IsZero() && !n.SubscribeOnly {
		n.Glanced = false
		n.ActivatedAt = time.Now()
	}
}

func (n *Notification) AfterCreate() {
	bongo.B.AfterCreate(n)
}

func (n *Notification) AfterUpdate() {
	bongo.B.AfterUpdate(n)
}

func (n *Notification) GetId() int64 {
	return n.Id
}

func (n Notification) TableName() string {
	return "notification.notification"
}

func NewNotification() *Notification {
	return &Notification{}
}

func (n *Notification) One(q *bongo.Query) error {
	return bongo.B.One(n, n, q)
}

func (n *Notification) Create() error {
	// TODO check notification content existence
	if err := n.FetchByContent(); err != nil {
		if err != gorm.RecordNotFound {
			return err
		}

		return bongo.B.Create(n)
	}

	return nil
}

func (n *Notification) Upsert() error {
	unsubscribedAt := n.UnsubscribedAt

	if err := n.FetchByContent(); err != nil {
		if err != gorm.RecordNotFound {
			return err
		}

		return bongo.B.Create(n)
	}
	n.UnsubscribedAt = unsubscribedAt

	return bongo.B.Update(n)
}

func (n *Notification) Subscribe(nc *NotificationContent) error {
	n.UnsubscribedAt = ZeroDate()

	return n.subscription(nc)
}

func (n *Notification) Unsubscribe(nc *NotificationContent) error {
	n.UnsubscribedAt = time.Now()

	return n.subscription(nc)
}

func (n *Notification) subscription(nc *NotificationContent) error {
	if nc.TargetId == 0 {
		return errors.New("target id cannot be empty")
	}
	nc.TypeConstant = NotificationContent_TYPE_COMMENT

	if err := nc.Create(); err != nil {
		return err
	}

	n.NotificationContentId = nc.Id
	n.SubscribeOnly = true

	return n.Upsert()
}

func (n *Notification) List(q *models.Query) (*NotificationResponse, error) {
	if q.Limit == 0 {
		return nil, errors.New("limit cannot be zero")
	}
	response := &NotificationResponse{}
	result, err := n.getDecoratedList(q)
	if err != nil {
		return response, err
	}

	response.Notifications = result
	response.UnreadCount = getUnreadNotificationCount(result)

	return response, nil
}

func (n *Notification) Some(data interface{}, q *bongo.Query) error {

	return bongo.B.Some(n, data, q)
}

func (n *Notification) fetchByAccountId(q *models.Query) ([]Notification, error) {
	var notifications []Notification

	err := bongo.B.DB.Table(n.TableName()).
		Where("NOT (activated_at IS NULL OR activated_at <= '0001-01-02') AND account_id = ?", q.AccountId).
		Order("activated_at desc").
		Limit(q.Limit).
		Find(&notifications).Error

	if err != gorm.RecordNotFound && err != nil {
		return nil, err
	}

	return notifications, nil
}

func (n *Notification) FetchByContent() error {
	selector := map[string]interface{}{
		"account_id":              n.AccountId,
		"notification_content_id": n.NotificationContentId,
	}
	q := bongo.NewQS(selector)

	return n.One(q)
}

// getDecoratedList fetches notifications of the given user and decorates it with
// notification activity actors
func (n *Notification) getDecoratedList(q *models.Query) ([]NotificationContainer, error) {
	result := make([]NotificationContainer, 0)

	nList, err := n.fetchByAccountId(q)
	if err != nil {
		return nil, err
	}
	// fetch all notification content relationships
	contentIds := deductContentIds(nList)

	nc := NewNotificationContent()
	ncMap, err := nc.FetchMapByIds(contentIds)
	if err != nil {
		return nil, err
	}

	na := NewNotificationActivity()
	naMap, err := na.FetchMapByContentIds(contentIds)
	if err != nil {
		return nil, err
	}

	for _, n := range nList {
		nc := ncMap[n.NotificationContentId]
		na := naMap[n.NotificationContentId]
		container := n.buildNotificationContainer(q.AccountId, &nc, na)
		result = append(result, container)
	}

	return result, nil
}

func (n *Notification) buildNotificationContainer(actorId int64, nc *NotificationContent, na []NotificationActivity) NotificationContainer {
	ct, err := CreateNotificationContentType(nc.TypeConstant)
	if err != nil {
		return NotificationContainer{}
	}

	ct.SetTargetId(nc.TargetId)
	ct.SetListerId(actorId)
	ac, err := ct.FetchActors(na)
	if err != nil {
		return NotificationContainer{}
	}
	latestActorsOldIds, _ := models.AccountOldsIdByIds(ac.LatestActors)

	return NotificationContainer{
		TargetId:              nc.TargetId,
		TypeConstant:          nc.TypeConstant,
		UpdatedAt:             n.ActivatedAt,
		Glanced:               n.Glanced,
		NotificationContentId: nc.Id,
		LatestActors:          ac.LatestActors,
		LatestActorsOldIds:    latestActorsOldIds,
		ActorCount:            ac.Count,
	}
}

func deductContentIds(nList []Notification) []int64 {
	notificationContentIds := make([]int64, len(nList))
	for _, n := range nList {
		notificationContentIds = append(notificationContentIds, n.NotificationContentId)
	}

	return notificationContentIds
}

func (n *Notification) FetchContent() (*NotificationContent, error) {
	nc := NewNotificationContent()
	if err := nc.ById(n.NotificationContentId); err != nil {
		return nil, err
	}

	return nc, nil
}

func (n *Notification) Glance() error {
	selector := map[string]interface{}{
		"glanced":    false,
		"account_id": n.AccountId,
	}

	set := map[string]interface{}{
		"glanced": true,
	}

	return bongo.B.UpdateMulti(n, selector, set)
}

func getUnreadNotificationCount(notificationList []NotificationContainer) int {
	unreadCount := 0
	for _, nc := range notificationList {
		if !nc.Glanced {
			unreadCount++
		}
	}

	return unreadCount
}

func (n *Notification) MapMessage(data []byte) error {
	if err := json.Unmarshal(data, n); err != nil {
		return err
	}

	return nil
}

func (n *Notification) FetchLastActivity() (*NotificationActivity, *NotificationContent, error) {
	// fetch notification content and get event type
	nc, err := n.FetchContent()
	if err != nil {
		return nil, nil, err
	}

	a := NewNotificationActivity()
	a.NotificationContentId = nc.Id

	if err := a.LastActivity(); err != nil {
		return nil, nil, err
	}

	return a, nc, nil
}
