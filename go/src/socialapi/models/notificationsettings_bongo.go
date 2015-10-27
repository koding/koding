package models

import (
	"fmt"
	"time"

	"github.com/koding/bongo"
)

// TO-DO
//
// Are you sure to add this notification settings into the api schema
// If not , think about more for it about pros and cons
//
//~Mehmet Ali
const NotificationSettingsBongoName = "api.notification_settings"

func (n NotificationSettings) GetId() int64 {
	return n.Id
}

func (n NotificationSettings) BongoName() string {
	return NotificationSettingsBongoName
}

func (n *NotificationSettings) Update() error {
	if n.ChannelId == 0 || n.AccountId == 0 {
		return fmt.Errorf("Validation failed ChannelId: %s - AccountId:%s", n.ChannelId, n.AccountId)
	}

	return bongo.B.Update(n)
}

func (n *NotificationSettings) AfterCreate() {
	bongo.B.AfterCreate(n)
}

func (n *NotificationSettings) AfterUpdate() {
	bongo.B.AfterUpdate(n)
}

func (n *NotificationSettings) BeforeCreate() error {
	if err := n.validateBeforeOps(); err != nil {
		return err
	}
	now := time.Now().UTC()
	n.CreatedAt = now
	n.UpdatedAt = now

	return nil
}

// BeforeUpdate runs before updating struct
func (n *NotificationSettings) BeforeUpdate() error {
	return n.validateBeforeOps()
}

func (n *NotificationSettings) One(q *bongo.Query) error {
	return bongo.B.One(n, n, q)
}

func (n *NotificationSettings) ById(id int64) error {
	return bongo.B.ById(n, id)
}

func (n *NotificationSettings) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(n, data, q)
}

func (n *NotificationSettings) validateBeforeOps() error {
	if n.AccountId == 0 {
		return ErrAccountIdIsNotSet
	}

	if n.ChannelId == 0 {
		return ErrChannelIdIsNotSet
	}

	// a := NewAccount()
	_, err := Cache.Account.ById(n.AccountId)
	if err != nil {
		return err
	}

	_, err = Cache.Channel.ById(n.ChannelId)
	if err != nil {
		return err
	}

	// We should add group && group control ??

	return nil
}
