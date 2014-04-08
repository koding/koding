package models

import (
	// "errors"
	"fmt"
	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
	"time"
)

var (
	FETCH_LIMIT = 50
)

type Notification struct {
	Id                    int64     `json:"id"`
	AccountId             int64     `json:"accountId"             sql:"NOT NULL"`
	NotificationContentId int64     `json:"notificationContentId" sql:"NOT NULL"`
	Glanced               bool      `json:"glanced"               sql:"NOT NULL"`
	UpdatedAt             time.Time `json:"updatedAt"             sql:"NOT NULL"`
}

func (n *Notification) GetId() int64 {
	return n.Id
}

func (n *Notification) TableName() string {
	return "notification"
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

func (n *Notification) List(q *Query) ([]NotificationContainer, error) {
	q.Limit = 8

	result, err := n.getDecoratedList(q)
	if err != nil {
		return nil, err
	}

	result, err = populateActors(result)
	if err != nil {
		return nil, err
	}

	return result, nil
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
		Limit: FETCH_LIMIT,
		Skip:  q.Skip,
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

func (n *Notification) decorateContents(result []NotificationContainer, resultMap *map[string]struct{}, q *Query) ([]NotificationContainer, error) {

	nList, err := n.fetchByAccountId(q)
	if nList == nil {
		return result, nil
	}

	// fetch all notification content relationships
	ncMap, err := fetchRelatedContent(nList)
	if err != nil {
		return nil, err
	}

	for _, n := range nList {
		nc := ncMap[n.NotificationContentId]
		key := prepareResultKey(&nc)
		if _, ok := (*resultMap)[key]; !ok {
			container := buildNotificationContainer(&nc)
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
		TargetId: nc.TargetId,
		Type:     nc.Type,
	}
}

func prepareResultKey(nc *NotificationContent) string {
	return fmt.Sprintf("%s_%d", nc.Type, nc.TargetId)
}

func fetchRelatedContent(nl []Notification) (map[int64]NotificationContent, error) {
	notificationContentIds := make([]int64, 0)
	for _, n := range nl {
		notificationContentIds = append(notificationContentIds, n.NotificationContentId)
	}
	nc := NewNotificationContent()
	return nc.FetchMapByIds(notificationContentIds)
}

// fetch 3 actors and total count of actors
func populateActors(result []NotificationContainer) ([]NotificationContainer, error) {
	return result, nil
}
