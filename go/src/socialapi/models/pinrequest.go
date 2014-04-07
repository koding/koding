package models

type PinRequest struct {
	MessageId int64  `json:"messageId"`
	GroupName string `json:"groupName"`
	AccountId int64  `json:"accountId"`
}

func NewPinRequest() *PinRequest {
	return &PinRequest{
		GroupName: Channel_KODING_NAME,
	}
}
