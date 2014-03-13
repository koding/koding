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

	//Base model operations
	m Model
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

func (c *Channel) GetId() int64 {
	return c.Id
}

func (c *Channel) TableName() string {
	return "channel"
}

func (c *Channel) Self() Modellable {
	return c
}

func (c *Channel) Fetch() error {
	return c.m.Fetch(c)
}

func (c *Channel) Update() error {
	if c.Name == "" || c.Group == "" {
		return errors.New(fmt.Sprintf("Validation failed %s - %s", c.Name, c.Group))
	}

	return c.m.Update(c)
}

func (c *Channel) Create() error {
	if c.Name == "" || c.Group == "" {
		return errors.New(fmt.Sprintf("Validation failed %s - %s", c.Name, c.Group))
	}

	return c.m.Create(c)
}

func (c *Channel) Delete() error {
	return c.m.Delete(c)
}
