package models

type PinRequest struct {
	MessageId int64  `json:"messageId"`
	GroupName string `json:"groupName"`
	AccountId int64  `json:"accountId"`
}
