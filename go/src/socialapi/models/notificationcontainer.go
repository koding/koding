package models

import (
	"time"
)

type NotificationContainer struct {
	TypeConstant string    `json:"typeConstant"`
	TargetId     int64     `json:"targetId"`
	Glanced      bool      `json:"glanced"`
	LatestActors []int64   `json:"latestActors"`
	UpdatedAt    time.Time `json:"updatedAt"`
	ActorCount   int       `json:"actorCount"`
}

type ActorContainer struct {
	LatestActors []int64
	Count        int
}

func NewNotificationContainer() *NotificationContainer {
	return &NotificationContainer{}
}

func NewActorContainer() *ActorContainer {
	return &ActorContainer{}
}
