package models

import (

	"github.com/koding/bongo"
)

func (c *ChannelParticipant) Update() error {
	return bongo.B.Update(c)
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
