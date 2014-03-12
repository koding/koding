package models

import (
	"errors"
	"socialapi/db"
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
	now := time.Now().UTC()
	return &ChannelMessageList{
		ChannelId: 1,
		MessageId: 1,
		AddedAt:   now,
	}
}

func (c *ChannelMessageList) Fetch() error {
	if err := db.DB.First(c, c.Id).Error; err != nil {
		return err
	}
	return nil
}

func (c *ChannelMessageList) Save() error {
	c.AddedAt = time.Now().UTC()

	if err := db.DB.Save(c).Error; err != nil {
		return err
	}
	return nil
}

func (c *ChannelMessageList) Delete() error {
	if c.Id == 0 {
		return errors.New("Channel id is not set")
	}

	if err := db.DB.Delete(c).Error; err != nil {
		return err
	}

	return nil
}
