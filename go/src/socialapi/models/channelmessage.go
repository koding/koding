package models

import "time"

type ChannelMessage struct {
	// unique identifier of the channel message
	Id int64

	// Body of the mesage
	Body string

	// type of the message
	Type int

	// Creator of the channel message
	AccountId int64

	// Creation date of the message
	CreatedAt time.Time

	// Modification date of the message
	UpdatedAt time.Time
	m         Model
}

func (c *ChannelMessage) GetId() int64 {
	return c.Id
}

func (c *ChannelMessage) TableName() string {
	return "channel_message"
}

func (c *ChannelMessage) Self() Modellable {
	return c
}

const (
	POST int = iota
	JOIN
	LEAVE
	CHAT
)

func NewChannelMessage() *ChannelMessage {
	return &ChannelMessage{}
}

func (c *ChannelMessage) Fetch() error {
	return c.m.Fetch(c)
}

func (c *ChannelMessage) Update() error {
	// only update body
	return c.m.UpdatePartial(c,
		map[string]interface{}{
			"body": c.Body,
		},
	)
}

func (c *ChannelMessage) Create() error {
	return c.m.Create(c)
}

func (c *ChannelMessage) Delete() error {
	return c.m.Delete(c)
}

func (c *ChannelMessage) FetchByIds(ids []int64) ([]ChannelMessage, error) {
	var messages []ChannelMessage

	if len(ids) == 0 {
		return messages, nil
	}

	if err := c.m.FetchByIds(c, &messages, ids); err != nil {
		return nil, err
	}
	return messages, nil
}
