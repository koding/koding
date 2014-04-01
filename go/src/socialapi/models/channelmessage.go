package models

import (
	"errors"
	"time"

	"github.com/koding/bongo"
)

type ChannelMessage struct {
	// unique identifier of the channel message
	Id int64 `json:"id"`

	// Body of the mesage
	Body string `json:"body"`

	// Generated Slug for body
	Slug string `json:"slug" 			           sql:"NOT NULL;UNIQUE"`

	// type of the message
	Type string `json:"type"                        sql:"NOT NULL"`

	// Creator of the channel message
	AccountId int64 `json:"accountId"               sql:"NOT NULL"`

	// in which channel this message is created
	InitialChannelId int64 `json:"initialChannelId" sql:"NOT NULL"`

	// Creation date of the message
	CreatedAt time.Time `json:"createdAt"           sql:"DEFAULT:CURRENT_TIMESTAMP"`

	// Modification date of the message
	UpdatedAt time.Time `json:"updatedAt"           sql:"DEFAULT:CURRENT_TIMESTAMP"`
}

func (c *ChannelMessage) AfterCreate() {
	bongo.B.AfterCreate(c)
}

func (c *ChannelMessage) AfterUpdate() {
	bongo.B.AfterUpdate(c)
}

func (c *ChannelMessage) AfterDelete() {
	bongo.B.AfterDelete(c)
}

func (c *ChannelMessage) GetId() int64 {
	return c.Id
}

func (c *ChannelMessage) TableName() string {
	return "channel_message"
}

const (
	ChannelMessage_TYPE_POST  = "post"
	ChannelMessage_TYPE_REPLY = "reply"
	ChannelMessage_TYPE_JOIN  = "join"
	ChannelMessage_TYPE_LEAVE = "leave"
	ChannelMessage_TYPE_CHAT  = "chat"
)

func NewChannelMessage() *ChannelMessage {
	return &ChannelMessage{}
}

func (c *ChannelMessage) Fetch() error {
	return bongo.B.Fetch(c)
}

func (c *ChannelMessage) Update() error {
	// only update body
	err := bongo.B.UpdatePartial(c,
		map[string]interface{}{
			"body": c.Body,
		},
	)
	return err
}

func (c *ChannelMessage) Create() error {
	var err error
	c, err = Slugify(c)
	if err != nil {
		return err
	}

	return bongo.B.Create(c)
}

func (c *ChannelMessage) Delete() error {
	return bongo.B.Delete(c)
}

func (c *ChannelMessage) FetchByIds(ids []int64) ([]ChannelMessage, error) {
	var messages []ChannelMessage

	if len(ids) == 0 {
		return messages, nil
	}

	if err := bongo.B.FetchByIds(c, &messages, ids); err != nil {
		return nil, err
	}
	return messages, nil
}

func (c *ChannelMessage) FetchRelatives() (*ChannelMessageContainer, error) {
	if c.Id == 0 {
		return nil, errors.New("Channel message id is not set")
	}
	container := NewChannelMessageContainer()
	container.Message = c

	i := NewInteraction()
	i.MessageId = c.Id

	interactions, err := i.List("like")
	if err != nil {
		return nil, err
	}

	interactionContainer := NewInteractionContainer()
	interactionContainer.Actors = interactions
	// check this from database
	interactionContainer.IsInteracted = true

	if container.Interactions == nil {
		container.Interactions = make(map[string]*InteractionContainer)
	}
	if _, ok := container.Interactions["like"]; !ok {
		container.Interactions["like"] = NewInteractionContainer()
	}
	container.Interactions["like"] = interactionContainer
	return container, nil
}
