package models

import (
	// "errors"
	// "fmt"
	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
	"time"
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

func (n *Notification) One(selector map[string]interface{}) error {
	return bongo.B.One(n, n, selector)
}

func (n *Notification) Create() error {
	s := map[string]interface{}{
		"account_id":              n.AccountId,
		"notification_content_id": n.NotificationContentId,
	}

	if err := n.One(s); err != nil {
		if err != gorm.RecordNotFound {
			return err
		}

		return bongo.B.Create(n)
	}

	return bongo.B.Update(n)
}
