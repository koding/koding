package models

// Channel request is used for channel authentication/
type ChannelRequest struct {
	Id    int64  `json:"id"`
	Name  string `json:"name"`
	Group string `json:"group"`
	Type  string `json:"typeConstant"`
}

type PushMessage struct {
	Channel *Channel `json:"channel"`
	Message
}

type UpdateInstanceMessage struct {
	Token        string `json:"token"`
	ChannelToken string `json:"channelToken"`
	Message
}

type NotificationMessage struct {
	Account   *Account            `json:"account"`
	Body      NotificationContent `json:"body"`
	EventName string              `json:"eventName"`
	EventId   string              `json:"eventId"`
}

type Message struct {
	Id        int64       `json:"messageId, string"`
	EventName string      `json:"eventName"`
	Body      interface{} `json:"body"`
	EventId   string      `json:"eventId"`
}

type Authenticate struct {
	Account *Account
	Channel ChannelInterface
}

// Namings are for backward compatibility
type NotificationContent struct {
	Context  string      `json:"context"`
	Event    string      `json:"event"`
	Contents interface{} `json:"contents"`
}

type CheckParticipationResponse struct {
	Channel      *Channel `json:"channel"`
	Account      *Account `json:"account"`
	AccountToken string   `json:"accountToken"`
}

type Account struct {
	Id       int64  `json:"id,string"`
	Nickname string `json:"nick"`
	Token    string `json:"token"`
}

type RevokeChannelAccess struct {
	Id           int64    `json:"id,string"`
	Tokens       []string `json:"tokens"`
	ChannelToken string   `json:"channelToken"`
}
