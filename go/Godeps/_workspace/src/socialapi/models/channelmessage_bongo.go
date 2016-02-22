package models

import (
	"time"

	"github.com/koding/bongo"
)

const ChannelMessageBongoName = "api.channel_message"

func (c *ChannelMessage) BeforeCreate() error {
	c.CreatedAt = time.Now().UTC()
	c.UpdatedAt = time.Now().UTC()
	c.DeletedAt = ZeroDate()
	c.Token = NewToken(c.CreatedAt).String()
	return c.MarkIfExempt()
}

func (c *ChannelMessage) BeforeUpdate() error {
	c.DeletedAt = ZeroDate()
	c.UpdatedAt = time.Now().UTC()

	return c.MarkIfExempt()
}

func (c *ChannelMessage) AfterCreate() {
	bongo.B.AfterCreate(c)
}

func (c *ChannelMessage) AfterUpdate() {
	bongo.B.AfterUpdate(c)
}

func (c *ChannelMessage) AfterDelete() {
	bongo.B.AfterDelete(c)
}

func (c ChannelMessage) GetId() int64 {
	return c.Id
}

func (c ChannelMessage) BongoName() string {
	return ChannelMessageBongoName
}

func (c ChannelMessage) TableName() string {
	return c.BongoName()
}

func NewChannelMessage() *ChannelMessage {
	return &ChannelMessage{
		TypeConstant: ChannelMessage_TYPE_POST,
	}
}

// Update only updates the body field of the channel message
//
// tests are added for this function
func (c *ChannelMessage) Update() error {
	if err := bodyLenCheck(c.Body); err != nil {
		return err
	}

	cm := NewChannelMessage()
	if err := cm.ById(c.GetId()); err != nil {
		return err
	}

	if cm.TypeConstant == ChannelMessage_TYPE_JOIN ||
		cm.TypeConstant == ChannelMessage_TYPE_LEAVE ||
		cm.TypeConstant == ChannelMessage_TYPE_SYSTEM {
		return ErrChannelMessageUpdatedNotAllowed
	}

	cm.Body = c.Body
	cm.Payload = c.Payload

	return bongo.B.Update(cm)

	// todo implement UpdatePartial
	// only update body
	// err := bongo.B.UpdatePartial(c,
	// 	map[string]interface{}{
	// 		"Body": c.Body,
	// 	},
	// )
	// return err
}

// Create creates the channel message
//
// tests are added for this function
func (c *ChannelMessage) Create() error {
	if err := bodyLenCheck(c.Body); err != nil {
		return err
	}

	if err := c.validateSystemMessage(); err != nil {
		return err
	}

	var err error
	c, err = Slugify(c)
	if err != nil {
		return err
	}

	return bongo.B.Create(c)
}

func (c *ChannelMessage) ById(id int64) error {
	return bongo.B.ById(c, id)
}

func (c *ChannelMessage) UnscopedById(id int64) error {
	return bongo.B.UnscopedById(c, id)
}

func (c *ChannelMessage) One(q *bongo.Query) error {
	return bongo.B.One(c, c, q)
}

func (c *ChannelMessage) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(c, data, q)
}

func (c *ChannelMessage) UpdateMulti(rest ...map[string]interface{}) error {
	return bongo.B.UpdateMulti(c, rest...)
}

func (c *ChannelMessage) CountWithQuery(q *bongo.Query) (int, error) {
	return bongo.B.CountWithQuery(c, q)
}

func (c *ChannelMessage) Delete() error {
	return bongo.B.DB.Unscoped().Delete(c).Error
}

func (c *ChannelMessage) validateSystemMessage() error {

	if c.TypeConstant != ChannelMessage_TYPE_SYSTEM {
		return nil
	}

	if val := c.GetPayload("systemType"); val == nil {
		return ErrSystemTypeIsNotSet
	}

	return nil
}
