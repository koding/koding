package models

import (
	"errors"
	"fmt"
	"time"
)

type Channel struct {
	// unique identifier of the channel
	Id int64

	// Name of the channel
	Name string

	// Creator of the channel
	CreatorId int64

	// Name of the group which channel is belong to
	Group string

	// Purpose of the channel
	Purpose string

	// Secret key of the channel for event propagation purposes
	// we can put this key into another table?
	SecretKey string

	// Type of the channel
	Type int

	// Privacy constant of the channel
	Privacy int

	// Creation date of the channel
	CreatedAt time.Time

	// Modification date of the channel
	UpdatedAt time.Time
}

const (
	TOPIC int = iota
	// CHAT
	GROUP
)

const (
	PUBLIC int = iota
	PRIVATE
)

func NewChannel() *Channel {
	return &Channel{
		Name:      "koding-main",
		CreatorId: 123,
		Group:     "koding",
		Purpose:   "string",
		SecretKey: "string",
		Type:      GROUP,
		Privacy:   PRIVATE,
	}
}

func (c *Channel) Fetch() error {
	if err := First(c, c.Id); err != nil {
		return err
	}
	return nil
}

func (c *Channel) Update() error {
	if c.Id == 0 {
		return errors.New("Channel id is not set")
	}
	return c.Save()
}

func (c *Channel) Save() error {

	// todo add validation rules for name, group
	if c.Name == "" || c.Group == "" {
		return errors.New(fmt.Sprintf("Validation failed %s - %s", c.Name, c.Group))
	}

	if err := Save(c); err != nil {
		return err
	}
	return nil
}

func (c *Channel) Delete() error {
	if c.Id == 0 {
		return errors.New("Channel id is not set")
	}

	if err := Delete(c); err != nil {
		return err
	}

	return nil
}
