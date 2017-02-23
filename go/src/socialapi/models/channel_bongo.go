package models

import (
	"fmt"
	"socialapi/request"
	"time"

	"github.com/koding/bongo"
)

const ChannelBongoName = "api.channel"

func (c Channel) GetId() int64 {
	return c.Id
}

func (c Channel) BongoName() string {
	return ChannelBongoName
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
	// first delete channel list relations
	messageMap, err := c.deleteChannelLists()
	if err != nil {
		fmt.Printf("channel delete error: %s \n", err)

		// in case of an error delete the messages up to that point
		if err := c.deleteChannelMessages(messageMap); err != nil {
			fmt.Printf("channel message delete error: %s \n", err)
		}

		return err
	}

	// and delete messages
	if err := c.deleteChannelMessages(messageMap); err != nil {
		return err
	}

	participants, err := c.FetchParticipantIds(&request.Query{})
	if err != nil {
		return err
	}

	var errRemove error
	for _, participantId := range participants {
		if err := c.RemoveParticipant(participantId); err != nil && errRemove == nil {
			errRemove = err
		}
	}

	if errRemove != nil {
		return errRemove
	}

	return bongo.B.Delete(c)
}

func (c *Channel) DeleteWithParticipantsForce() error {
	// firstly, delete the channel participants
	if err := c.DeleteChannelParticipants(); err != nil {
		return err
	}

	// then delete the channels itself
	return c.DeleteHard()
}

func (c *Channel) DeleteHard() error {
	return bongo.B.DB.Model(c).Table(c.BongoName()).Unscoped().Delete(c).Error
}

func (c *Channel) UnscopedById(id int64) error {
	return bongo.B.UnscopedById(c, id)
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
