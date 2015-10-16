package models

import socialapimodels "socialapi/models"

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
	Account   *socialapimodels.Account `json:"account"`
	Body      NotificationContent      `json:"body"`
	EventName string                   `json:"eventName"`
	EventId   string                   `json:"eventId"`
}

// BroadcastMessage holds required parameters for sending broadcast message
type BroadcastMessage struct {
	EventId   string              `json:"eventId"`
	GroupName string              `json:"groupName"`
	EventName string              `json:"eventName"`
	Body      NotificationContent `json:"body"`
}

type Message struct {
	Id        int64       `json:"messageId, string"`
	EventName string      `json:"eventName"`
	Body      interface{} `json:"body"`
	EventId   string      `json:"eventId"`
}

type Authenticate struct {
	Account *socialapimodels.Account
	Channel ChannelManager
}

// Namings are for backward compatibility
type NotificationContent struct {
	Context  string      `json:"context"`
	Event    string      `json:"event"`
	Contents interface{} `json:"contents"`
}

type CheckParticipationResponse struct {
	Channel      *Channel                 `json:"channel"`
	Account      *socialapimodels.Account `json:"account"`
	AccountToken string                   `json:"accountToken"`
}

type RevokeChannelAccess struct {
	Id           int64    `json:"id,string"`
	Tokens       []string `json:"tokens"`
	ChannelToken string   `json:"channelToken"`
}
