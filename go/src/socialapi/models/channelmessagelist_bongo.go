package models

import (
	"time"

	"github.com/koding/bongo"
)

func (c *ChannelMessageList) BeforeCreate() error {
	c.AddedAt = time.Now()
	c.RevisedAt = time.Now()

	return c.MarkIfExempt()
}

func (c *ChannelMessageList) BeforeUpdate() error {
	return c.MarkIfExempt()
}

func (c *ChannelMessageList) AfterCreate() {
	bongo.B.AfterCreate(c)
}

func (c *ChannelMessageList) AfterUpdate() {
	bongo.B.AfterUpdate(c)
}

func (c ChannelMessageList) AfterDelete() {
	bongo.B.AfterDelete(c)
}

func (c ChannelMessageList) GetId() int64 {
	return c.Id
}

func (c ChannelMessageList) BongoName() string {
	return "api.channel_message_list"
}

func (c ChannelMessageList) TableName() string {
	return c.BongoName()
}

func NewChannelMessageList() *ChannelMessageList {
	return &ChannelMessageList{}
}

func (c *ChannelMessageList) ById(id int64) error {
	return bongo.B.ById(c, id)
}

func (c *ChannelMessageList) One(q *bongo.Query) error {
	return bongo.B.One(c, c, q)
}

func (c *ChannelMessageList) Update() error {
	return bongo.B.Update(c)
}

func (c *ChannelMessageList) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(c, data, q)
}

func (c *ChannelMessageList) CountWithQuery(q *bongo.Query) (int, error) {
	return bongo.B.CountWithQuery(c, q)
}

func (c *ChannelMessageList) Create() error {
	return bongo.B.Create(c)
}

func (c *ChannelMessageList) Delete() error {
	return bongo.B.DB.Model(c).Unscoped().Delete(c).Error
}

func (c *ChannelMessageList) Emit(eventName string, data interface{}) error {
	return bongo.B.Emit(c.BongoName()+"_"+eventName, data)
}
