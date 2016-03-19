package models

import (
	"time"

	"github.com/koding/bongo"
)

func (c ChannelParticipant) GetId() int64 {
	return c.Id
}

func (c ChannelParticipant) BongoName() string {
	return "api.channel_participant"
}

func (c *ChannelParticipant) BeforeCreate() error {
	c.LastSeenAt = time.Now().UTC()

	return c.MarkIfExempt()
}

func (c *ChannelParticipant) BeforeUpdate() error {
	c.LastSeenAt = time.Now().UTC()

	return c.MarkIfExempt()
}

func (c *ChannelParticipant) AfterCreate() {
	bongo.B.AfterCreate(c)
}

func (c *ChannelParticipant) AfterUpdate() {
	bongo.B.AfterUpdate(c)
}

func (c ChannelParticipant) AfterDelete() {
	bongo.B.AfterDelete(c)
}

func (c *ChannelParticipant) Update() error {
	return bongo.B.Update(c)
}

func (c *ChannelParticipant) DeleteForce() error {
	return bongo.B.Delete(c)
}

func (c *ChannelParticipant) ById(id int64) error {
	return bongo.B.ById(c, id)
}

func (c *ChannelParticipant) One(q *bongo.Query) error {
	return bongo.B.One(c, c, q)
}

func (c *ChannelParticipant) Count(where ...interface{}) (int, error) {
	return bongo.B.Count(c, where...)
}

func (c *ChannelParticipant) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(c, data, q)
}
