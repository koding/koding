package models

import (
	"errors"
	"time"

	"github.com/koding/bongo"
)

type Interaction struct {
	// unique identifier of the Interaction
	Id int64 `json:"id"`

	// Id of the interacted message
	MessageId int64 `json:"messageId"`

	// Id of the actor
	AccountId int64 `json:"accountId"`

	// Type of the interaction
	Type string `json:"type"`

	// Creation of the interaction
	CreatedAt time.Time `json:"createdAt"`
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

func (i *Interaction) Self() bongo.Modellable {
	return i
}

func NewInteraction() *Interaction {
	return &Interaction{}
}

func (i *Interaction) Fetch() error {
	return bongo.B.Fetch(i)
}

func (i *Interaction) Create() error {
	return bongo.B.Create(i)
}

func (i *Interaction) Delete() error {
	if err := bongo.B.DB.
		Where("message_id = ? and account_id = ?", i.MessageId, i.AccountId).
		Delete(i.Self()).Error; err != nil {
		return err
	}
	return nil
}

func (c *Interaction) List(interactionType string) ([]int64, error) {
	var interations []int64

	if c.MessageId == 0 {
		return interations, errors.New("ChannelId is not set")
	}

	if err := bongo.B.DB.Table(c.TableName()).
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
