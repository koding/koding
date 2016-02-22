package models

import (
	"socialapi/models"
	"time"

	"github.com/koding/bongo"
)

func (n *Notification) BeforeCreate() {
	if n.UnsubscribedAt.IsZero() && n.SubscribedAt.IsZero() {
		n.SubscribedAt = time.Now().UTC()
	}
}

func (n *Notification) BeforeUpdate() {
	if n.UnsubscribedAt.IsZero() && !n.SubscribeOnly {
		n.Glanced = false
		n.ActivatedAt = time.Now().UTC()
	}
}

func (n *Notification) AfterCreate() {
	bongo.B.AfterCreate(n)
}

func (n *Notification) AfterUpdate() {
	bongo.B.AfterUpdate(n)
}

func (n Notification) GetId() int64 {
	return n.Id
}

func (n Notification) BongoName() string {
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
		if err != bongo.RecordNotFound {
			return err
		}

		return bongo.B.Create(n)
	}

	return nil
}

func (n *Notification) Delete() error {
	return bongo.B.Delete(n)
}

func (n *Notification) ByContentId(contentId int64) error {
	if contentId == 0 {
		return models.ErrIdIsNotSet
	}

	selector := map[string]interface{}{
		"notification_content_id": contentId,
	}

	return n.One(bongo.NewQS(selector))
}

func (n *Notification) Some(data interface{}, q *bongo.Query) error {

	return bongo.B.Some(n, data, q)
}
