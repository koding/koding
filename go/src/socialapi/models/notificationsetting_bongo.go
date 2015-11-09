package models

import (
	"fmt"
	"time"

	"github.com/koding/bongo"
)

const NotificationSettingBongoName = "notification.notification_setting"

func (n NotificationSetting) GetId() int64 {
	return n.Id
}

func (n NotificationSetting) BongoName() string {
	return NotificationSettingBongoName
}

func (n *NotificationSetting) Create() error {
	if n.AccountId == 0 {
		return ErrAccountIdIsNotSet
	}

	if n.ChannelId == 0 {
		return ErrChannelIdIsNotSet
	}

	return bongo.B.Create(n)
}

func (n *NotificationSetting) Update() error {
	if n.ChannelId == 0 || n.AccountId == 0 {
		return fmt.Errorf("Update failed ChannelId: %s - AccountId:%s", n.ChannelId, n.AccountId)
	}

	return bongo.B.Update(n)
}

func (n *NotificationSetting) Delete() error {
	selector := map[string]interface{}{
		"channel_id": n.ChannelId,
		"account_id": n.AccountId,
	}

	if err := n.One(bongo.NewQS(selector)); err != nil {
		return err
	}

	return bongo.B.Delete(n)
}

func (n *NotificationSetting) AfterCreate() {
	bongo.B.AfterCreate(n)
}

func (n *NotificationSetting) AfterUpdate() {
	bongo.B.AfterUpdate(n)
}

func (n *NotificationSetting) AfterDelete() {
	bongo.B.AfterDelete(n)
}

func (n *NotificationSetting) BeforeCreate() error {
	if err := n.validateBeforeOps(); err != nil {
		return err
	}
	now := time.Now().UTC()
	n.CreatedAt = now
	n.UpdatedAt = now

	return nil
}

// BeforeUpdate runs before updating struct
func (n *NotificationSetting) BeforeUpdate() error {
	return n.validateBeforeOps()
}

func (n *NotificationSetting) One(q *bongo.Query) error {
	return bongo.B.One(n, n, q)
}

func (n *NotificationSetting) ById(id int64) error {
	return bongo.B.ById(n, id)
}

func (n *NotificationSetting) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(n, data, q)
}

func (n *NotificationSetting) validateBeforeOps() error {
	if n.AccountId == 0 {
		return ErrAccountIdIsNotSet
	}

	if n.ChannelId == 0 {
		return ErrChannelIdIsNotSet
	}

	_, err := Cache.Account.ById(n.AccountId)
	if err != nil {
		return err
	}

	_, err = Cache.Channel.ById(n.ChannelId)
	if err != nil {
		return err
	}

	return nil
}
