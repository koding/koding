package models

type Realtimer interface {
	UpdateChannel(req *PushMessage) error
	UpdateInstance(req *UpdateInstanceMessage) error
	NotifyUser(req *NotificationMessage) error
}
