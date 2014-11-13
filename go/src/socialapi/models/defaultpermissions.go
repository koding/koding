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

var (
	REQUEST_NAME_MESSAGE_UPDATE = "message-update"
	REQUEST_NAME_MESSAGE_DELETE = "message-delete"
	REQUEST_NAME_MESSAGE_GET    = "message-get"
)
