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
	n.CreatedAt = time.Now().UTC()
	insertSql := "INSERT INTO " +
		n.BongoName() +
		` ("channel_id","account_id","desktop_setting","mobile_setting","is_muted",` +
		`"is_suppressed", "created_at", "updated_at")` +
		"VALUES ($1,$2,$3,$4,$5,$6,$7,$8) " +
		"RETURNING ID"

	err := bongo.B.DB.DB().QueryRow(insertSql, n.ChannelId, n.AccountId,
		n.DesktopSetting, n.MobileSetting, n.IsMuted, n.IsSuppressed,
		n.CreatedAt, n.UpdatedAt).Scan(&n.Id)

	if err == nil {
		n.AfterCreate()

	}

	return err
}

func (n *NotificationSetting) Update() error {
	if n.ChannelId == 0 || n.AccountId == 0 {
		return fmt.Errorf("Update failed ChannelId: %s - AccountId:%s", n.ChannelId, n.AccountId)
	}

	n.UpdatedAt = time.Now().UTC()

	insertSql := "UPDATE " +
		n.BongoName() +
		` SET "channel_id" = $1 ,"account_id" = $2,"desktop_setting" = $3,"mobile_setting" = $4,"is_muted" = $5,` +
		`"is_suppressed" = $6, "updated_at" = $7`

	_, err := bongo.B.DB.DB().Exec(insertSql, n.ChannelId, n.AccountId,
		n.DesktopSetting, n.MobileSetting, n.IsMuted, n.IsSuppressed,
		n.UpdatedAt)

	if err == nil {
		n.AfterUpdate()
	}

	return err
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
