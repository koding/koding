package models

import (
	"time"
)

type NotificationContainer struct {
	TypeConstant          string    `json:"typeConstant"`
	TargetId              int64     `json:"targetId"`
	Glanced               bool      `json:"glanced"`
	LatestActors          []string  `json:"latestActors"`
	UpdatedAt             time.Time `json:"updatedAt"`
	ActorCount            int       `json:"actorCount"`
	NotificationContentId int64     `json:"-"`
}

type ActorContainer struct {
	LatestActors []string
	Count        int
}

func NewNotificationContainer() *NotificationContainer {
	return &NotificationContainer{}
}

func NewActorContainer() *ActorContainer {
	return &ActorContainer{}
}
