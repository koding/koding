package models

type NotificationContainer struct {
	Type     string         `json:"type"`
	TargetId int64          `json:"targetId"`
	Content  string         `json:"content"`
    Glanced  bool           `json:"glanced"`
	Actors   ActorContainer `json:"actors"`
}

type ActorContainer struct {
	LatestActors []int64 `json:"actors"`
	Count        int     `json:"count"`
}

func NewNotificationContainer() *NotificationContainer {
	return &NotificationContainer{}
}

func NewActorContainer() *ActorContainer {
	return &ActorContainer{}
}
