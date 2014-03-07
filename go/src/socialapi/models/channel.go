package models

import "time"

type Channel struct {
	// unique identifier of the channel
	Id int64

	// Name of the channel
	Name string

	// Creator of the channel
	CreatorId int64

	// Name of the group which channel is belong to
	Group string

	// Purpose of the channel
	Purpose string

	// Secret key of the channel for event propagation purposes
	// we can put this key into another table?
	SecretKey string

	// Type of the channel
	Type ChannelType

	// Privacy constant of the channel
	Privacy ChannelPrivacy

	// Creation date of the channel
	CreatedAt time.Time

	// Modification date of the channel
	ModifiedAt time.Time
}

type ChannelType int

const (
	TOPIC ChannelType = iota
	CHAT
	GROUP
)

type ChannelPrivacy int

const (
	PUBLIC ChannelPrivacy = iota
	PRIVATE
)
