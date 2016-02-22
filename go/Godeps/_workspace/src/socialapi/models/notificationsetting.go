package models

import (
	"time"

	"github.com/cihangir/nisql"
	"github.com/koding/bongo"
)

type NotificationSetting struct {
	// unique idetifier of the notification setting
	Id int64 `json:"id,string"`

	// ChannelId is the id of the channel
	ChannelId int64 `json:"channelId,string"       sql:"NOT NULL"`

	// AccountId is the creator of the notification settting
	AccountId int64 `json:"accountId,string"               sql:"NOT NULL"`

	// DesktopSetting holds dektop setting type
	DesktopSetting nisql.NullString `json:"desktopSetting"` //	sql:"NOT NULL"`

	// MobileSetting holds mobile setting type
	MobileSetting nisql.NullString `json:"mobileSetting"` //	sql:"NOT NULL"`

	// IsMuted holds the data if channel is muted or not
	IsMuted nisql.NullBool `json:"isMuted"`

	// IsSuppressed holds data that getting notification when @channel is written
	// If user doesn't want to get notification
	// when written to channel @channel, @here or name of the user.
	// User uses 'suppress' feature and doesn't get notification
	IsSuppressed nisql.NullBool `json:"isSuppressed"`

	// Creation date of the notification settings
	CreatedAt time.Time `json:"createdAt"          sql:"NOT NULL"`

	// Modification date of the notification settings
	UpdatedAt time.Time `json:"updatedAt"          sql:"NOT NULL"`
}

const (
	// Describes that user want to be notified for all notifications
	NotificationSetting_STATUS_ALL = "all"
	// Describes that user want to be notified
	// for user's own name or with highlighted words
	NotificationSetting_STATUS_PERSONAL = "personal"
	// Describes that user doesn't want to get any notification
	NotificationSetting_STATUS_NEVER = "never"
)

func NewNotificationSetting() *NotificationSetting {
	now := time.Now().UTC()
	return &NotificationSetting{
		CreatedAt: now,
		UpdatedAt: now,
	}
}

func (ns *NotificationSetting) RemoveNotificationSettings(channelIds ...int64) error {
	return ns.removeNotificationSettings(channelIds...)
}

func (ns *NotificationSetting) removeNotificationSettings(channelIds ...int64) error {
	if ns.AccountId == 0 {
		return ErrAccountIdIsNotSet
	}

	if len(channelIds) == 0 {
		return nil
	}

	for _, channelId := range channelIds {
		n := NewNotificationSetting()
		n.AccountId = ns.AccountId
		n.ChannelId = channelId

		err := n.FetchNotificationSetting()
		if err != nil && err != bongo.RecordNotFound {
			return err
		}

		if err := n.Delete(); err != nil {
			if err != bongo.RecordNotFound {
				return err
			}
		}

	}

	return nil
}

// FetchNotificationSetting fetches the notification setting with given
// channelId and accountId.
func (ns *NotificationSetting) FetchNotificationSetting() error {
	if ns.ChannelId == 0 {
		return ErrChannelIdIsNotSet
	}

	if ns.AccountId == 0 {
		return ErrAccountIdIsNotSet
	}

	selector := map[string]interface{}{
		"channel_id": ns.ChannelId,
		"account_id": ns.AccountId,
	}

	return ns.fetchNotificationSetting(selector)
}

func (ns *NotificationSetting) fetchNotificationSetting(selector map[string]interface{}) error {
	if ns.ChannelId == 0 {
		return ErrChannelIdIsNotSet
	}

	if ns.AccountId == 0 {
		return ErrAccountIdIsNotSet
	}

	return ns.One(bongo.NewQS(selector))
}
