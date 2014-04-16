package models

type PrivateMessageRequest struct {
	Body       string
	GroupName  string
	Recepients []int64
	AccountId  int64
}
