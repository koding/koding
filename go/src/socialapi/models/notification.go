package models

import (
	// "errors"
	"fmt"
	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
	"math"
	"time"
)

var (
	FETCH_LIMIT = 50
)

type Notification struct {
	Id int64 `json:"id"`
	// notification recipient
	AccountId int64 `json:"accountId" sql:"NOT NULL"`
	// notification content foreign key
	NotificationContentId int64 `json:"notificationContentId" sql:"NOT NULL"`
	// glanced information
	Glanced bool `json:"glanced" sql:"NOT NULL"`
	// last notifier addition time
	UpdatedAt time.Time `json:"updatedAt" sql:"NOT NULL"`
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
	s := map[string]interface{}{
		"account_id":              n.AccountId,
		"notification_content_id": n.NotificationContentId,
	}
	q := bongo.NewQS(s)
	if err := n.One(q); err != nil {
		if err != gorm.RecordNotFound {
			return err
		}

		return bongo.B.Create(n)
	}

	n.Glanced = false

	return bongo.B.Update(n)
}

func (n *Notification) List(q *Query) (*NotificationResponse, error) {
	if err := n.isAccountValid(q.AccountId); err != nil {
		return nil, err
	}

	limit := math.Min(float64(q.Limit), 8.0)
	q.Limit = int(limit)

	response := &NotificationResponse{}
	result, err := n.getDecoratedList(q)
	if err != nil {
		return response, err
	}

	result, err = populateActors(q.AccountId, result)
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
	query := &bongo.Query{
		Selector: map[string]interface{}{
			"account_id": q.AccountId,
		},
		Sort: map[string]string{
			"updated_at": "desc",
		},
		Pagination: bongo.Pagination{
			Limit: FETCH_LIMIT,
			Skip:  q.Skip,
		},
	}
	if err := bongo.B.Some(n, &notifications, query); err != nil {
		return nil, err
	}

	return notifications, nil
}

// prepareNotifications
func (n *Notification) getDecoratedList(q *Query) ([]NotificationContainer, error) {
	result := make([]NotificationContainer, 0)
	resultMap := make(map[string]struct{}, 0)

	var err error
	result, err = n.decorateContents(result, &resultMap, q)
	if err != nil {
		return nil, err
	}

	return result, nil
}

// decorateContents recursively fetches notification data till it reaches the FETCH_LIMIT
func (n *Notification) decorateContents(result []NotificationContainer, resultMap *map[string]struct{}, q *Query) ([]NotificationContainer, error) {

	nList, err := n.fetchByAccountId(q)
	if nList == nil {
		return result, nil
	}

	// fetch all notification content relationships
	ncMap, err := fetchRelatedContents(nList)
	if err != nil {
		return nil, err
	}

	for _, n := range nList {
		nc := ncMap[n.NotificationContentId]
		key := prepareResultKey(&nc)
		if _, ok := (*resultMap)[key]; !ok {
			container := buildNotificationContainer(&nc)
			container.UpdatedAt = n.UpdatedAt // fetch latest notification timestamp
			container.Glanced = n.Glanced
			(*resultMap)[key] = struct{}{}
			result = append(result, container)
			if len(result) == q.Limit {
				return result, nil
			}
		}
	}

	if len(nList) == FETCH_LIMIT {
		q.Skip += FETCH_LIMIT
		return n.decorateContents(result, resultMap, q)
	}

	return result, nil
}

func buildNotificationContainer(nc *NotificationContent) NotificationContainer {
	return NotificationContainer{
		TargetId:     nc.TargetId,
		TypeConstant: nc.TypeConstant,
	}
}

func prepareResultKey(nc *NotificationContent) string {
	return fmt.Sprintf("%s_%d", nc.TypeConstant, nc.TargetId)
}

func fetchRelatedContents(nl []Notification) (map[int64]NotificationContent, error) {
	notificationContentIds := make([]int64, 0)
	for _, n := range nl {
		notificationContentIds = append(notificationContentIds, n.NotificationContentId)
	}
	nc := NewNotificationContent()
	return nc.FetchMapByIds(notificationContentIds)
}

func (n *Notification) FetchContent() (*NotificationContent, error) {
	nc := NewNotificationContent()
	nc.Id = n.NotificationContentId
	if err := nc.Fetch(); err != nil {
		return nil, err
	}

	return nc, nil
}

func (n *Notification) Follow(a *Activity) error {
	a.TypeConstant = NotificationContent_TYPE_FOLLOW
	// create activity
	if err := a.Create(); err != nil {
		return err
	}

	fn := NewFollowNotification()
	fn.NotifierId = a.ActorId
	fn.TargetId = a.TargetId

	return CreateNotification(fn)
}

func (n *Notification) JoinGroup(a *Activity, admins []int64) error {
	a.TypeConstant = NotificationContent_TYPE_JOIN

	return n.interactGroup(a, admins)
}

func (n *Notification) LeaveGroup(a *Activity, admins []int64) error {
	a.TypeConstant = NotificationContent_TYPE_LEAVE

	return n.interactGroup(a, admins)
}

func (n *Notification) interactGroup(a *Activity, admins []int64) error {
	gn := NewGroupNotification(a.TypeConstant)
	gn.NotifierId = a.ActorId
	gn.TargetId = a.TargetId
	gn.Admins = admins

	if err := a.Create(); err != nil {
		return err
	}

	return CreateNotification(gn)
}

// populateActors fetches latest actor ids and total count of actors. recipientId is needed for excluding
// recipients own activities
func populateActors(recipientId int64, ncList []NotificationContainer) ([]NotificationContainer, error) {
	result := make([]NotificationContainer, 0)

	for _, n := range ncList {
		notificationType, err := CreateNotificationType(n.TypeConstant)
		if err != nil {
			return nil, err
		}

		notificationType.SetTargetId(n.TargetId)
		notificationType.SetListerId(recipientId)

		actors, err := notificationType.FetchActors()
		// instead of interrupting process we can just proceed here
		if err != nil {
			return nil, err
		}

		n.LatestActors = actors.LatestActors
		n.ActorCount = actors.Count
		result = append(result, n)
	}

	return result, nil
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
	if err := n.isAccountValid(n.AccountId); err != nil {
		return err
	}

	selector := map[string]interface{}{
		"glanced":    false,
		"account_id": n.AccountId,
	}

	set := map[string]interface{}{
		"glanced": true,
	}

	return bongo.B.UpdateMulti(n, selector, set)
}

func (n *Notification) isAccountValid(accountId int64) error {
	a := NewAccount()
	a.Id = accountId

	return a.Fetch()
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
