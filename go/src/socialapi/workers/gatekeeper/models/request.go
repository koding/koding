package models

// Channel request is used for channel authentication/
type ChannelRequest struct {
	Id    int64  `json:"id,string"`
	Name  string `json:"name"`
	Group string `json:"group"`
	Type  string `json:"typeConstant"`
}

type PushMessage struct {
	Channel *Channel `json:"channel"`
	Message
}

type UpdateInstanceMessage struct {
	Message
}

type NotificationMessage struct {
	Nickname  string              `json:"nickname"`
	Body      NotificationContent `json:"body"`
	EventName string              `json:"eventName"`
}

type Message struct {
	Token     string      `json:"token"`
	EventName string      `json:"eventName"`
	Body      interface{} `json:"body"`
}

type AuthRequest struct {
	ChannelId int64  `json:"channelId,string"`
	EventName string `json:"eventName"`
}

type Channel struct {
	Id          int64    `json:"id"`
	Name        string   `json:"name"`
	Type        string   `json:"typeConstant"`
	Group       string   `json:"groupName"`
	SecretNames []string `json:"secretNames"`
}

// Namings are for backward compatibility
type NotificationContent struct {
	Context  string      `json:"context"`
	Event    string      `json:"event"`
	Contents interface{} `json:"contents"`
}
