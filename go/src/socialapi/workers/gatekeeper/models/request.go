package models

// Channel request is used for channel authentication
type ChannelRequest struct {
	Request
type PushRequest struct {
	ChannelId int64 `json:"channelId,string"`
	PushMessage
}

type PushMessage struct {
	EventName string           `json:"eventName"`
	Body      interface{}      `json:"body"`
	Channel   *ChannelResponse `json:"-"`
}

// General purpose Request struct
type Request struct {
	Name  string `json:"name"`
	Group string `json:"group"`
	Type  string `json:"typeConstant"`
}
