package models

import (
	"fmt"
	"time"

	"github.com/koding/bongo"

	"socialapi/request"
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

func getMessageBatch(channelId int64, c int) ([]ChannelMessage, error) {
	messageIds, err := NewChannelMessageList().
		FetchMessageIdsByChannelId(channelId, &request.Query{
		Skip:  c * 100,
		Limit: 100,
	})
	if err != nil {
		return nil, err
	}
	return NewChannelMessage().FetchByIds(messageIds)
}

func isMessageCrossIndexed(messageId int64) (error, bool) {
	count, err := NewChannelMessageList().CountWithQuery(&bongo.Query{
		Selector: map[string]interface{}{
			"message_id": messageId,
		},
	})
	if err != nil {
		return err, false
	}
	return nil, count > 1
}

func (c *Channel) deleteChannelMessages() error {
	if c.Id == 0 {
		return ErrIdIsNotSet
	}
	for i := 0; ; i++ {
		messages, err := getMessageBatch(c.Id, i)
		if err != nil {
			return err
		}
		for _, message := range messages {
			err, isCrossIndexed := isMessageCrossIndexed(message.Id)
			if err != nil {
				return err
			}

			if isCrossIndexed {
				continue
			}

			if err = message.Delete(); err != nil {
				return err
			}
		}
		if len(messages) < 100 {
			return nil
		}
	}
}

func getListingBatch(channelId int64, c int) ([]ChannelMessageList, error) {
	var listings []ChannelMessageList
	q := &bongo.Query{
		Selector: map[string]interface{}{"channel_id": channelId},
		Pagination: bongo.Pagination{
			Skip:  100 * c,
			Limit: 100,
		}}
	if err := NewChannelMessageList().Some(&listings, q); err != nil {
		return nil, err
	}
	return listings, nil
}

func (c *Channel) deleteChannelLists() error {
	for i := 0; ; i++ {
		listings, err := getListingBatch(c.Id, i)
		if err != nil {
			return err
		}

		for _, listing := range listings {
			if err := listing.Delete(); err != nil {
				return err
			}
		}
		if len(listings) < 100 {
			return nil
		}
	}
}
