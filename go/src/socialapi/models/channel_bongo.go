package models

import (
	"fmt"
	"time"

	"github.com/koding/bongo"
)

const ChannelTableName = "api.channel"

func (c Channel) GetId() int64 {
	return c.Id
}

func (c Channel) TableName() string {
	return ChannelTableName
}

func (c *Channel) AfterCreate() {
	bongo.B.AfterCreate(c)
}

func (c *Channel) AfterUpdate() {
	bongo.B.AfterUpdate(c)
}

func (c Channel) AfterDelete() {
	bongo.B.AfterDelete(c)
}

func (c *Channel) BeforeCreate() error {
	c.CreatedAt = time.Now().UTC()
	c.UpdatedAt = time.Now().UTC()
	c.DeletedAt = ZeroDate()
	c.Token = NewToken(c.CreatedAt).String()

	return c.MarkIfExempt()
}

func (c *Channel) BeforeUpdate() error {
	c.UpdatedAt = time.Now()

	return c.MarkIfExempt()
}

func (c *Channel) Update() error {
	if c.Name == "" || c.GroupName == "" {
		return fmt.Errorf("Validation failed Name: %s - GroupName:%s", c.Name, c.GroupName)
	}

	return bongo.B.Update(c)
}

func (c *Channel) Delete() error {
	if err := c.deleteChannelMessages(); err != nil {
		return err
	}

	if err := c.deleteChannelLists(); err != nil {
		return err
	}

	return bongo.B.Delete(c)
}

func (c *Channel) ById(id int64) error {
	return bongo.B.ById(c, id)
}

func (c *Channel) One(q *bongo.Query) error {
	return bongo.B.One(c, c, q)
}

func (c *Channel) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(c, data, q)
}

func (c *Channel) FetchByIds(ids []int64) ([]Channel, error) {
	var channels []Channel

	if len(ids) == 0 {
		return channels, nil
	}

	if err := bongo.B.FetchByIds(c, &channels, ids); err != nil {
		return nil, err
	}
	return channels, nil
}

func (c *Channel) CountWithQuery(q *bongo.Query) (int, error) {
	return bongo.B.CountWithQuery(c, q)
}
