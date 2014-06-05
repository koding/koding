package models

import (
	"time"
)

type NotificationContainer struct {
	TypeConstant          string    `json:"typeConstant"`
	TargetId              int64     `json:"targetId,string"`
	Glanced               bool      `json:"glanced"`
	LatestActors          []int64   `json:"latestActors"`
	LatestActorsOldIds    []string  `json:"latestActorsOldIds"`
	UpdatedAt             time.Time `json:"updatedAt"`
	ActorCount            int       `json:"actorCount"`
	NotificationContentId int64     `json:"-"`
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
