package models

import "time"

type UnifiedMessageReplies struct {
	Id int64

	SourceUnifiedMessageId int64
	SourceUnifiedMessage   UnifiedMessage

	TargetUnifiedMessageId int64
	TargetUnifiedMessage   UnifiedMessage

	CreatedAt time.Time
}
