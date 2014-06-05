package models

type PrivateMessageRequest struct {
	Body       string `json:"body"`
	GroupName  string `json:"groupName"`
	Recipients []int64
	AccountId  int64 `json:"accountId,string"`
}
