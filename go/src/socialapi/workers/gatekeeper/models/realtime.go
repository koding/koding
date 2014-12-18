package models

type Realtime interface {
	Push(req *PushMessage) error
	UpdateInstance(req *UpdateInstanceMessage) error
	NotifyUser(req *NotificationMessage) error
}
