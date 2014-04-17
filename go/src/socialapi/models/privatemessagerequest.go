package models

type PrivateMessageRequest struct {
	Body       string
	GroupName  string
	Recipients []int64
	AccountId  int64
}
