package models

import (
	// "errors"
	"fmt"
	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
	"time"
)

type Notifiee struct {
	Id             int64     `json:"id"`
	AccountId      int64     `json:"accountId"      sql:"NOT NULL"`
	NotificationId int64     `json:"notificationId" sql:"NOT NULL"`
	Glanced        bool      `json:"glanced"`
	UpdatedAt      time.Time `json:"updatedAt"`
}

func (n *Notifiee) GetId() int64 {
	return n.Id
}

func (n *Notifiee) TableName() string {
	return "notifiee"
}

func NewNotifiee() *Notifiee {
	return &Notifiee{}
}

func (n *Notifiee) One(selector map[string]interface{}) error {
	return bongo.B.One(n, n, selector)
}

func (n *Notifiee) Create() error {
	s := map[string]interface{}{
		"account_id":      n.AccountId,
		"notification_id": n.NotificationId,
	}
	fmt.Printf("first %+v", n)
	if err := n.One(s); err != nil {
		if err != gorm.RecordNotFound {
			return err
		}
	}
	fmt.Printf("second %+v", n)

	return bongo.B.Create(n)
}
