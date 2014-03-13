package models

import "time"

type ChannelMessageList struct {
	// unique identifier of the channel message list
	Id int64

	// Id of the channel
	ChannelId int64

	// Id of the message
	MessageId int64

	// Addition date of the message to the channel
	AddedAt time.Time

	//Base model operations
	m Model
}

func (c *ChannelMessageList) GetId() int64 {
	return c.Id
}

func (c *ChannelMessageList) TableName() string {
	return "channel_message_list"
}

func (c *ChannelMessageList) Self() Modellable {
	return c
}

func NewChannelMessageList() *ChannelMessageList {
	return &ChannelMessageList{}
}

func (c *ChannelMessageList) Fetch() error {
	return c.m.Fetch(c)
}

func (c *ChannelMessageList) Create() error {
	return c.m.Create(c)
}

func (c *ChannelMessageList) Delete() error {
	return c.m.Delete(c)
}
