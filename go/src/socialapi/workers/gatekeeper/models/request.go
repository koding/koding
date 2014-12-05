package models

// Channel request is used for channel authentication/
type ChannelRequest struct {
	Id    int64  `json:"id"`
	Name  string `json:"name"`
	Group string `json:"group"`
	Type  string `json:"typeConstant"`
}

type PushMessage struct {
	ChannelId int64            `json:"channelId,string"`
	EventName string           `json:"eventName"`
	Body      interface{}      `json:"body"`
	Channel   *ChannelResponse `json:"-"`
}

type AuthRequest struct {
	ChannelId int64  `json:"channelId,string"`
	EventName string `json:"eventName"`
}

type ChannelResponse struct {
	Id          string   `json:"id"`
	Name        string   `json:"name"`
	Type        string   `json:"typeConstant"`
	Group       string   `json:"groupName"`
	SecretNames []string `json:"secretNames"`
}
