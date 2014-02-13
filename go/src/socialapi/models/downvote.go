package models

import "time"

type Downvote struct {
	Id               int64
	AccountId        int64
	UnifiedMessageId int64
	CreatedAt        time.Time
}
