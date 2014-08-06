package models

type PinRequest struct {
	MessageId int64  `json:"messageId,string"`
	GroupName string `json:"groupName"`
	AccountId int64  `json:"accountId,string"`
}

func NewPinRequest() *PinRequest {
	return &PinRequest{
		GroupName: Channel_KODING_NAME,
	}
}

type PinnedChannelListUpdatedEvent struct {
	Channel Channel        `json:"channel"`
	Message ChannelMessage `json:"message"`
	Reply   ChannelMessage `json:"reply"`
}
