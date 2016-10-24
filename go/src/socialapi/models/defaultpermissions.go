package models

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

const (
	DispatcherEvent = "dispatcher-event"
)

const (
	SlackListUsers     = "slack-list-users"
	SlackListChannels  = "slack-list-channels"
	SlackTeamInfo      = "slack-team-information"
	SlackPostMessage   = "slack-post-message"
	SlackSlashCommand  = "slack-slash-command"
	SlackOauthCallback = "slack-oauth-callback"
	SlackOauthSuccess  = "slack-oauth-succeess"
	SlackOauthSend     = "slack-oauth-send"
	MailPublishEvent   = "mail-publish-event"
)
