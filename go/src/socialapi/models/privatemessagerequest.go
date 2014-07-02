package models

type PrivateMessageRequest struct {
	Body       string `json:"body"`
	GroupName  string `json:"groupName"`
	Recipients []string
	AccountId  int64 `json:"accountId,string"`
}
