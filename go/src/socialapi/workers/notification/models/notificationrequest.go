package models

type NotificationRequest struct {
	AccountId    int64 `json:"accountId"`
	TargetId     int64 `json:"targetId"`
	TypeConstant int64 `json:"typeConstant"`
}

func NewNotificationRequest() *NotificationRequest {
	return &NotificationRequest{}
}
