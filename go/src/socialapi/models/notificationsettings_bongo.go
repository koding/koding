package models

import (
	"time"

	"github.com/koding/bongo"
)

// TO-DO
//
// Are you sure to add this notification settings into the api schema
// If not , think about more for it about pros and cons
//
//~Mehmet Ali
const NotificationSettingsBongoName = "api.channel"

func (n NotificationSettings) GetId() int64 {
	return n.Id
}

func (n NotificationSettings) BongoName() string {
	return NotificationSettingsBongoName
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
	n.CreatedAt = time.Now().UTC()
	n.UpdatedAt = time.Now().UTC()

	return
}

func (n *NotificationSettings) validateBeforeOps() error {
	if n.AccountId == 0 {
		return ErrAccountIdIsNotSet
	}

	if n.ChannelId == 0 {
		return ErrChannelIdIsNotSet
	}

	a := NewAccount()
	if err := a.ById(n.AccountId); err != nil {
		return err
	}

	l := NewChannel()
	if err := l.ById(n.ChannelId); err != nil {
		return err
	}
	// We should add group && group control ??

	return nil
}
