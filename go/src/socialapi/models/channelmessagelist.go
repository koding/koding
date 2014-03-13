package models

import (
	"errors"
	"time"
)

type ChannelMessageList struct {
	// unique identifier of the channel message list
	Id int64

	// Id of the channel
	ChannelId int64

	// Id of the message
	MessageId int64

	// Addition date of the message to the channel
	AddedAt time.Time
}

func NewChannelMessageList() *ChannelMessageList {
	return &ChannelMessageList{}
}

func (c *ChannelMessageList) Fetch() error {
	if err := First(c, c.Id); err != nil {
		return err
	}
	return nil
}

func (c *ChannelMessageList) Save() error {
	// add those time related properties on write time
	// from database with now() command
	c.AddedAt = time.Now().UTC()

	if err := Save(c); err != nil {
		return err
	}
	return nil
}

func (c *ChannelMessageList) Delete() error {
	if c.Id == 0 {
		return errors.New("Channel id is not set")
	}

	if err := Delete(c); err != nil {
		return err
	}

	return nil
}
