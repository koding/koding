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
	AccountId int64

	// Creation date of the message
	CreatedAt time.Time

	// Modification date of the message
	UpdatedAt time.Time
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
		Type:      POST,
		CreatedAt: now,
		UpdatedAt: now,
	}
}

func (c ChannelMessage) TableName() string {
	return "channel_message"
}

func (c *ChannelMessage) Fetch() error {
	if c.Id == 0 {
		return errors.New("Channel message id is not set")
	}
	if err := First(c, c.Id); err != nil {
		return err
	}
	return nil
}

func (c *ChannelMessage) Update() error {
	if c.Id == 0 {
		return errors.New("Channel message id is not set")
	}

	if err := db.DB.
		Table(c.TableName()).
		Where(c.Id).
		Update("body", c.Body).
		Error; err != nil {
		return err
	}

	return nil
}

func (c *ChannelMessage) Save() error {

	now := time.Now().UTC()
	// created at shouldnt be updated
	c.CreatedAt = now
	c.UpdatedAt = now

	if err := Save(c); err != nil {
		return err
	}
	return nil
}

func (c *ChannelMessage) Delete() error {
	if c.Id == 0 {
		return errors.New("Channel message id is not set")
	}

	if err := Delete(c); err != nil {
		return err
	}

	return nil
}
