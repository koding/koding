package models

import "time"

type Comment struct {
	// unique identifier of the channel message
	Id int64

	// holds parent message id of this comment
	MessageId int64

	// Body of the mesage
	Body string

	// type of the message
	Type int

	// Creator of the channel message
	CreatorId int64

	// Creation date of the message
	CreatedAt time.Time

	// Modification date of the message
	UpdatedAt time.Time
}
