package models

import "time"

type ChannelMessage struct {
	// unique identifier of the channel message
	Id int64

	// Body of the mesage
	Body string

	// type of the message
	Type MessageType

	// Creator of the channel
	CreatorId int64

	// Creation date of the message
	CreatedAt time.Time
}

type MessageType int

const (
	POST MessageType = iota
	JOIN
	LEAVE
	CHAT
)
