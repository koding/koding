package models

type Realtimer interface {
	UpdateChannel(req *PushMessage) error
	NotifyUser(req *NotificationMessage) error
}
