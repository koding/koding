package models

import (
	"errors"
	"socialapi/db"
	"time"
)

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

func (c *ChannelMessageList) BeforeCreate() {
	c.AddedAt = time.Now()
}

func (c *ChannelMessageList) BeforeUpdate() {
	c.AddedAt = time.Now()
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

	return c.m.Count(c,
		"channel_id = ? and added_at > ?",
		cp.ChannelId,
		// todo change this format to get from a specific place
		cp.LastSeenAt.UTC().Format(time.RFC822Z),
	)
}

func (c *ChannelMessageList) Create() error {
	return c.m.Create(c)
}

func (c *ChannelMessageList) Delete() error {
	return c.m.Delete(c)
}

func (c *ChannelMessageList) List(q *Query) (*HistoryResponse, error) {
	messageList, err := c.getMessages(q)
	if err != nil {
		return nil, err
	}

	hr := NewHistoryResponse()
	hr.MessageList = messageList

	cp := NewChannelParticipant()
	cp.ChannelId = c.ChannelId
	cp.AccountId = q.AccountId
	err = cp.FetchParticipant()
	if err != nil {
		return nil, err
	}

	if cp.Id == 0 {
		return nil, errors.New("Participant not found")
	}

	unreadCount, err := c.UnreadCount(cp)
	if err != nil {
		return nil, err
	}

	hr.UnreadCount = unreadCount
	return hr, nil
}

func (c *ChannelMessageList) getMessages(q *Query) ([]*ChannelMessageContainer, error) {
	var messages []int64

	if c.ChannelId == 0 {
		return nil, errors.New("ChannelId is not set")
	}

	if err := db.DB.Table(c.TableName()).
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
