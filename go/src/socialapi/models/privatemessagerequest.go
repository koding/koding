package models

type PrivateMessageRequest struct {
	Body       string `json:"body"`
	GroupName  string `json:"groupName"`
	Recipients []string
	AccountId  int64 `json:"accountId,string"`
	ChannelId  int64 `json:"channelId,string"`
}
