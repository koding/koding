package models

import "time"

type ChannelParticipant struct {
	// unique identifier of the channel
	Id int64

	// Id of the channel
	ChannelId int64

	// Id of the account
	AccountId int64

	// Status of the participant in the channel
	Status ParticipantStatus

	// date of the user's last access to regarding channel
	LastSeenAt time.Time

	// Creation date of the channel
	CreatedAt time.Time

	// Modification date of the channel
	ModifiedAt time.Time
}

type ParticipantStatus int

const (
	ACTIVE ParticipantStatus = iota
	LEFT
	REQUEST_PENDING
)
