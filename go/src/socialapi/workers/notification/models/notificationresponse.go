package models

type NotificationResponse struct {
	Notifications []NotificationContainer `json:"notificationList"`
	UnreadCount   int                     `json:"unreadCount"`
}
