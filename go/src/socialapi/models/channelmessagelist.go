package models

import "time"

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

func (c *ChannelMessageList) getMessages(q *Query) ([]ChannelMessage, error) {
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
	channelMessageReplies, err := parent.FetchByIds(messages)
	if err != nil {
		return nil, err
	}
	return channelMessageReplies, nil
}
