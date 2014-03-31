package models

import (
	"errors"
	"time"

	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
)

type ChannelMessageList struct {
	// unique identifier of the channel message list
	Id int64 `json:"id"`

	// Id of the channel
	ChannelId int64 `json:"channelId"`

	// Id of the message
	MessageId int64 `json:"messageId"`

	// Addition date of the message to the channel
	AddedAt time.Time `json:"addedAt"`
}

func (c *ChannelMessageList) BeforeCreate() {
	c.AddedAt = time.Now()
}

func (c *ChannelMessageList) BeforeUpdate() {
	c.AddedAt = time.Now()
}

func (c *ChannelMessageList) AfterCreate() {
	bongo.B.AfterCreate(c)
}

func (c *ChannelMessageList) AfterUpdate() {
	bongo.B.AfterUpdate(c)
}

func (c *ChannelMessageList) AfterDelete() {
	bongo.B.AfterDelete(c)
}

func (c *ChannelMessageList) GetId() int64 {
	return c.Id
}

func (c *ChannelMessageList) TableName() string {
	return "channel_message_list"
}

func NewChannelMessageList() *ChannelMessageList {
	return &ChannelMessageList{}
}

func (c *ChannelMessageList) Fetch() error {
	return bongo.B.Fetch(c)
}

func (c *ChannelMessageList) UnreadCount(cp *ChannelParticipant) (int, error) {
	if cp.ChannelId == 0 {
		return 0, errors.New("ChannelId is not set")
	}

	if cp.AccountId == 0 {
		return 0, errors.New("AccountId is not set")
	}

	if cp.LastSeenAt.IsZero() {
		return 0, errors.New("Last seen at date is not valid - it is zero")
	}

	return bongo.B.Count(c,
		"channel_id = ? and added_at > ?",
		cp.ChannelId,
		// todo change this format to get from a specific place
		cp.LastSeenAt.UTC().Format(time.RFC822Z),
	)
}

func (c *ChannelMessageList) Create() error {
	return bongo.B.Create(c)
}

func (c *ChannelMessageList) Delete() error {
	return bongo.B.Delete(c)
}

func (c *ChannelMessageList) List(q *Query) (*HistoryResponse, error) {
	messageList, err := c.getMessages(q)
	if err != nil {
		return nil, err
	}

	hr := NewHistoryResponse()
	hr.MessageList = messageList

	unreadCount := 0
	cp := NewChannelParticipant()
	cp.ChannelId = c.ChannelId
	cp.AccountId = q.AccountId
	err = cp.FetchParticipant()
	// we are forcing unread count to 0 if user is not a participant
	// of the channel
	if err != nil && err != gorm.RecordNotFound {
		return nil, err
	}

	if err == nil {
		unreadCount, err = c.UnreadCount(cp)
		if err != nil {
			return nil, err
		}
	}

	hr.UnreadCount = unreadCount
	return hr, nil
}

func (c *ChannelMessageList) getMessages(q *Query) ([]*ChannelMessageContainer, error) {
	var messages []int64

	if c.ChannelId == 0 {
		return nil, errors.New("ChannelId is not set")
	}

	if err := bongo.B.DB.Table(c.TableName()).
		Order("added_at desc").
		Where("channel_id = ?", c.ChannelId).
		Offset(q.Skip).
		Limit(q.Limit).
		Pluck("message_id", &messages).
		Error; err != nil {
		return nil, err
	}

	parent := NewChannelMessage()
	channelMessages, err := parent.FetchByIds(messages)
	if err != nil {
		return nil, err
	}

	populatedChannelMessages, err := c.populateChannelMessages(channelMessages)
	if err != nil {
		return nil, err
	}

	return populatedChannelMessages, nil
}

func (c *ChannelMessageList) populateChannelMessages(channelMessages []ChannelMessage) ([]*ChannelMessageContainer, error) {
	channelMessageCount := len(channelMessages)

	populatedChannelMessages := make([]*ChannelMessageContainer, channelMessageCount)

	if channelMessageCount == 0 {
		return populatedChannelMessages, nil
	}

	for i := 0; i < channelMessageCount; i++ {
		cm := channelMessages[i]
		cmc, err := cm.FetchRelatives()
		if err != nil {
			return nil, err
		}

		populatedChannelMessages[i] = cmc

		mr := NewMessageReply()
		mr.MessageId = cm.Id
		replies, err := mr.List()
		if err != nil {
			return nil, err
		}

		populatedChannelMessagesReplies := make([]*ChannelMessageContainer, len(replies))

		for rl := 0; rl < len(replies); rl++ {
			cmrc, err := replies[rl].FetchRelatives()
			if err != nil {
				return nil, err
			}
			populatedChannelMessagesReplies[rl] = cmrc
		}
		populatedChannelMessages[i].Replies = populatedChannelMessagesReplies

	}
	return populatedChannelMessages, nil

}

func (c *ChannelMessageList) FetchMessageChannels(messageId int64) ([]Channel, error) {
	var channelIds []int64
	selector := map[string]interface{}{
		"message_id": messageId,
	}

	pluck := map[string]interface{}{
		"channel_id": true,
	}

	err := bongo.B.Some(c, &channelIds, selector, nil, pluck)
	if err != nil {
		return nil, err
	}

	return NewChannel().FetchByIds(channelIds)
}

// seperate this fucntion into modelhelper
// as setting it to a variadic function
func (c *ChannelMessageList) DeleteMessagesBySelector(selector map[string]interface{}) error {
	var cmls []ChannelMessageList

	err := bongo.B.Some(c, &cmls, selector)
	if err != nil {
		return err
	}

	for _, cml := range cmls {
		if err := cml.Delete(); err != nil {
			return err
		}
	}
	return nil
}
