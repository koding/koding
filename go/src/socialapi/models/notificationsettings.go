package models

import "time"

type NotificationSettings struct {
	// unique idetifier of the notification setting
	Id int64 `json:"id,string"`

	// Id of the channel
	ChannelId int64 `json:"channelId,string"       sql:"NOT NULL"`

	// Creator of the notification settting
	AccountId int64 `json:"accountId,string"               sql:"NOT NULL"`

	// Holds dektop setting type
	DesktopSetting string `json:"desktopSetting"	sql:"NOT NULL"`

	// Holds mobile setting type
	MobileSetting string `json:"mobileSetting"			sql:"NOT NULL"`

	// Holds the data if channel is muted or not
	IsMuted bool `json:"isMuted"`

	// Holds data that getting notification when @channel is written
	// If user doesn't want to get notification
	// when written to channel @channel, @here or name of the user.
	// User uses 'suppress' feature and doesn't get notification
	IsSuppressed bool `json:"isSuppressed"`

	// Creation date of the notification settings
	CreatedAt time.Time `json:"createdAt"          sql:"NOT NULL"`

	// Modification date of the notification settings
	UpdatedAt time.Time `json:"updatedAt"          sql:"NOT NULL"`
}

const (
	// Describes that user want to be notified for all notifications
	NotificationSettings_STATUS_ALL = "all"
	// Describes that user want to be notified
	// for user's own name or with highlighted words
	NotificationSettings_STATUS_PERSONAL = "personal"
	// Describes that user doesn't want to get any notification
	NotificationSettings_STATUS_NEVER = "never"
)

func NewNotificationSettings() *NotificationSettings {
	now := time.Now().UTC()
	return &NotificationSettings{
		DesktopSetting: NotificationSettings_STATUS_ALL,
		MobileSetting:  NotificationSettings_STATUS_ALL,
		CreatedAt:      now,
		UpdatedAt:      now,
	}
}

func (ns *NotificationSettings) Defaults() *NotificationSettings {
	if ns.DesktopSetting == "" {
		ns.DesktopSetting = NotificationSettings_STATUS_ALL
	}

	if ns.MobileSetting == "" {
		ns.MobileSetting = NotificationSettings_STATUS_ALL
	}

	ns.IsMuted = false
	ns.IsSuppressed = false

	return ns
}
