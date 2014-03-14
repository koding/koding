package models

import (
	"errors"
	"socialapi/db"
	"time"
)

type Interaction struct {
	// unique identifier of the Interaction
	Id int64

	// Id of the interacted message
	MessageId int64

	// Id of the actor
	AccountId int64

	// Type of the interaction
	Type string

	// Creation of the interaction
	CreatedAt time.Time

	//Base model operations
	m Model
}

var AllowedInteractions = map[string]struct{}{
	"like":     struct{}{},
	"upvote":   struct{}{},
	"downvote": struct{}{},
}

const (
	Interaction_TYPE_LIKE     = "like"
	Interaction_TYPE_UPVOTE   = "upvote"
	Interaction_TYPE_DONWVOTE = "downvote"
)

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
	if err := db.DB.
		Where("message_id = ? and account_id = ?", i.MessageId, i.AccountId).
		Delete(i.Self()).Error; err != nil {
		return err
	}
	return nil
}

func (c *Interaction) List() ([]int64, error) {
	var interations []int64

	if c.MessageId == 0 {
		return interations, errors.New("ChannelId is not set")
	}

	if err := db.DB.Table(c.TableName()).
		Where("message_id = ?", c.MessageId).
		Pluck("account_id", &interations).
		Error; err != nil {
		return interations, nil
	}

	// change this part to use c.m.some

	// selector := map[string]interface{}{
	// 	"message_id": c.MessageId,
	// }

	// pluck := map[string]interface{}{
	// 	"account_id": true,
	// }

	// err := c.m.Some(c, &interations, selector, nil, pluck)
	// if err != nil && err != gorm.RecordNotFound {
	// 	return nil, err
	// }

	return interations, nil
}
