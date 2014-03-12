package models

import (
	"errors"
	"socialapi/db"
	"time"
)

type ChannelMessage struct {
	// unique identifier of the channel message
	Id int64

	// Body of the mesage
	Body string

	// type of the message
	Type int

	// Creator of the channel message
	CreatorId int64

	// Creation date of the message
	CreatedAt time.Time

	// Modification date of the message
	ModifiedAt time.Time
}

const (
	POST int = iota
	JOIN
	LEAVE
	CHAT
)

func NewChannelMessage() *ChannelMessage {
	now := time.Now().UTC()
	return &ChannelMessage{
		Type:       POST,
		CreatedAt:  now,
		ModifiedAt: now,
	}
}

func (c *ChannelMessage) Fetch() error {
	if err := db.DB.First(c, c.Id).Error; err != nil {
		return err
	}
	return nil
}

func (c *ChannelMessage) Update() error {
	if c.Id == 0 {
		return errors.New("Channel message id is not set")
	}
	return c.Save()
}

func (c *ChannelMessage) Save() error {

	now := time.Now().UTC()
	// created at shouldnt be updated
	c.CreatedAt = now
	c.ModifiedAt = now

	if err := db.DB.Save(c).Error; err != nil {
		return err
	}
	return nil
}

func (c *ChannelMessage) Delete() error {
	if c.Id == 0 {
		return errors.New("Channel message id is not set")
	}

	if err := db.DB.Delete(c).Error; err != nil {
		return err
	}

	return nil
}
