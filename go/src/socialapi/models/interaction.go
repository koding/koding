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
	Type int64

	// Creation of the interaction
	CreatedAt time.Time

	//Base model operations
	m Model
}

func (i *Interaction) GetId() int64 {
	return i.Id
}

func (i *Interaction) TableName() string {
	return "interaction"
}

func (i *Interaction) Self() Modellable {
	return i
}

func NewInteraction() *Interaction {
	return &Interaction{}
}

func (i *Interaction) Fetch() error {
	return i.m.Fetch(i)
}

func (i *Interaction) Create() error {
	return i.m.Create(i)
}

func (i *Interaction) Delete() error {
	return i.m.Delete(i)
}
