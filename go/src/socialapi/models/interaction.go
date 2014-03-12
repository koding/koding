package models

import "time"

type Interaction struct {
	// unique identifier of the Interaction
	Id int64

	// Id of the interacted message
	MessageId int64

	// Id of the actor
	AccountId int64

	// Type of the interaction
	Type InteractionType

	// Creation of the interaction
	CreatedAt time.Time
}

type InteractionType int

const (
	LIKE InteractionType = iota
	UPVOTE
	DOWN_VOTE
)
