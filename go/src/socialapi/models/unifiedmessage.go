package models

import "time"

type UnifiedMessage struct {
	Id           int64
	MessageType  string
	Body         string
	CreatedAt    time.Time
	UpdatedAt    time.Time
	DeletedAt    time.Time
	LikeCount    int64
	CommentCount int64
}
