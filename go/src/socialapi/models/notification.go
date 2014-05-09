package models

import (
	"errors"
	// "fmt"
	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
	"time"
)

type Notification struct {
	// unique identifier of Notification
	Id int64 `json:"id"`

	// notification recipient account id
	AccountId int64 `json:"accountId" sql:"NOT NULL"`

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
}

func (n *Notification) GetId() int64 {
	return n.Id
}

func (n Notification) TableName() string {
	return "api.notification"
}

func NewNotification() *Notification {
	return &Notification{}
}

func (n *Notification) One(q *bongo.Query) error {
	return bongo.B.One(n, n, q)
}

func (n *Notification) Create() error {
	unsubscribedAt := n.UnsubscribedAt

	// TODO check notification content existence
	if err := n.FetchByContent(); err != nil {
		if err != gorm.RecordNotFound {
			return err
		}

		return bongo.B.Create(n)
	}

	if !unsubscribedAt.Equal(ZeroDate()) {
		n.UnsubscribedAt = unsubscribedAt
	}

	return bongo.B.Update(n)
}

func (n *Notification) Subscribe(nc *NotificationContent) error {
	if nc.TargetId == 0 {
		return errors.New("target id cannot be empty")
	}
	nc.TypeConstant = NotificationContent_TYPE_COMMENT

	if err := nc.Create(); err != nil {
		return err
	}

	n.NotificationContentId = nc.Id

	return n.Create()
}

func (n *Notification) Unsubscribe(nc *NotificationContent) error {
	n.UnsubscribedAt = time.Now()

	return n.Subscribe(nc)
}

func (n *Notification) List(q *Query) (*NotificationResponse, error) {
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

func (n *Notification) fetchByAccountId(q *Query) ([]Notification, error) {
	var notifications []Notification

	err := bongo.B.DB.Table(n.TableName()).
		Where("NOT (activated_at IS NULL OR activated_at <= '0001-01-02') AND account_id = ?", q.AccountId).
		Order("activated_at desc").
		Limit(q.Limit).
		Find(&notifications).Error

	if err != nil {
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
func (n *Notification) getDecoratedList(q *Query) ([]NotificationContainer, error) {
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
	return NotificationContainer{
		TargetId:              nc.TargetId,
		TypeConstant:          nc.TypeConstant,
		UpdatedAt:             n.ActivatedAt,
		Glanced:               n.Glanced,
		NotificationContentId: nc.Id,
		LatestActors:          ac.LatestActors,
		ActorCount:            ac.Count,
	}
}

func deductContentIds(nList []Notification) []int64 {
	notificationContentIds := make([]int64, 0)
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

// func (n *Notification) Follow(a *NotificationActivity) error {
// 	// a.TypeConstant = NotificationContent_TYPE_FOLLOW
// 	// create NotificationActivity
// 	if err := a.Create(); err != nil {
// 		return err
// 	}

// 	fn := NewFollowNotification()
// 	fn.NotifierId = a.ActorId
// 	// fn.TargetId = a.TargetId

// 	return CreateNotificationContent(fn)
// }

// func (n *Notification) JoinGroup(a *NotificationActivity, admins []int64) error {
// 	// a.TypeConstant = NotificationContent_TYPE_JOIN

// 	return n.interactGroup(a, admins)
// }

// func (n *Notification) LeaveGroup(a *NotificationActivity, admins []int64) error {
// 	// a.TypeConstant = NotificationContent_TYPE_LEAVE

// 	return n.interactGroup(a, admins)
// }

// func (n *Notification) interactGroup(a *NotificationActivity, admins []int64) error {
// 	gn := NewGroupNotification(a.TypeConstant)
// 	gn.NotifierId = a.ActorId
// 	gn.TargetId = a.TargetId
// 	gn.Admins = admins

// 	if err := a.Create(); err != nil {
// 		return err
// 	}

// 	return CreateNotificationContent(gn)
// }

func (n *Notification) BeforeCreate() {
	if n.UnsubscribedAt.Equal(ZeroDate()) && n.SubscribedAt.Equal(ZeroDate()) {
		n.SubscribedAt = time.Now()
	}
}

func (n *Notification) BeforeUpdate() {
	if n.UnsubscribedAt.Equal(ZeroDate()) {
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

func (n *Notification) AfterDelete() {
	bongo.B.AfterDelete(n)
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
