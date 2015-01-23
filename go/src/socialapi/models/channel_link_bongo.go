package models

import (
	"time"

	"github.com/koding/bongo"
)

const ChannelLinkBongoName = "api.channel_link"

func (c *ChannelLink) BeforeCreate() error {
	c.CreatedAt = time.Now().UTC()
	return nil
}

func (c *ChannelLink) BeforeUpdate() error {
	return nil
}

func (c *ChannelLink) AfterCreate() {
	bongo.B.AfterCreate(c)
}

func (c *ChannelLink) AfterUpdate() {
	bongo.B.AfterUpdate(c)
}

func (c *ChannelLink) AfterDelete() {
	bongo.B.AfterDelete(c)
}

func (c ChannelLink) GetId() int64 {
	return c.Id
}

func (c ChannelLink) BongoName() string {
	return ChannelLinkBongoName
}

func (c ChannelLink) TableName() string {
	return c.BongoName()
}

func NewChannelLink() *ChannelLink {
	return &ChannelLink{}
}

func (c *ChannelLink) Update() error {
	return bongo.B.Update(c)
}

func (c *ChannelLink) Create() error {
	return bongo.B.Create(c)
}

func (c *ChannelLink) ById(id int64) error {
	return bongo.B.ById(c, id)
}

func (c *ChannelLink) UnscopedById(id int64) error {
	return bongo.B.UnscopedById(c, id)
}

func (c *ChannelLink) One(q *bongo.Query) error {
	return bongo.B.One(c, c, q)
}

func (c *ChannelLink) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(c, data, q)
}

func (c *ChannelLink) UpdateMulti(rest ...map[string]interface{}) error {
	return bongo.B.UpdateMulti(c, rest...)
}

func (c *ChannelLink) CountWithQuery(q *bongo.Query) (int, error) {
	return bongo.B.CountWithQuery(c, q)
}

func (c *ChannelLink) Delete() error {
	return bongo.B.DB.Unscoped().Delete(c).Error
}
