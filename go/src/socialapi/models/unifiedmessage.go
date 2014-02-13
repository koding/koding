package models

import "time"

type UnifiedMessage struct {
	Id int64

	MessageType string
	Body        string

	OriginType string
	OriginId   int64

	Group string

	CreatedAt    time.Time
	UpdatedAt    time.Time
	DeletedAt    time.Time
	LikeCount    int64
	CommentCount int64
}
