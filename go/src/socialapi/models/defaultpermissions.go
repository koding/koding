package models

var GroupChannelPermissions = map[string]Permission{
	REQUEST_NAME_MESSAGE_UPDATE: Permission{
		Name:           REQUEST_NAME_MESSAGE_UPDATE,
		StatusConstant: Permission_STATUS_ALLOWED,
	},

	REQUEST_NAME_MESSAGE_DELETE: Permission{
		Name:           REQUEST_NAME_MESSAGE_DELETE,
		StatusConstant: Permission_STATUS_ALLOWED,
	},

	REQUEST_NAME_MESSAGE_GET: Permission{
		Name:           REQUEST_NAME_MESSAGE_GET,
		StatusConstant: Permission_STATUS_ALLOWED,
	},
}

var DefaultPermissions = map[string]map[string]Permission{
	Channel_TYPE_GROUP: GroupChannelPermissions,
}

const (
	REQUEST_NAME_MESSAGE_UPDATE = "message-update"
	REQUEST_NAME_MESSAGE_DELETE = "message-delete"
	REQUEST_NAME_MESSAGE_GET    = "message-get"
)

const (
	ModerationChannelCreateLink = "moderation-channel-create-link"
	ModerationChannelGetLink    = "moderation-channel-get-link"
	ModerationChannelDeleteLink = "moderation-channel-delete-link"
	ModerationChannelBlacklist  = "moderation-channel-blacklist"
	ModerationChannelGetRoot    = "moderation-channel-get-root"
)
