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
	ChannelId int64 `json:"channelId"     sql:"NOT NULL"`

	// Id of the message
	MessageId int64 `json:"messageId"     sql:"NOT NULL"`

	// Addition date of the message to the channel
	AddedAt time.Time `json:"addedAt"     sql:"NOT NULL"`
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

func (c ChannelMessageList) AfterDelete() {
	bongo.B.AfterDelete(c)
}

func (c ChannelMessageList) GetId() int64 {
	return c.Id
}

func (c ChannelMessageList) TableName() string {
	return "api.channel_message_list"
}

func NewChannelMessageList() *ChannelMessageList {
	return &ChannelMessageList{}
}

func (c *ChannelMessageList) ById(id int64) error {
	return bongo.B.ById(c, id)
}

func (c *ChannelMessageList) One(q *bongo.Query) error {
	return bongo.B.One(c, c, q)
}

func (c *ChannelMessageList) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(c, data, q)
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

	query := bongo.B.DB.Table(c.TableName()).
		Offset(q.Skip).
		Limit(q.Limit).
		Order("added_at desc")

	if !q.From.IsZero() {
		query = query.Where("added_at < ?", q.From)
	}

	query = query.Where("channel_id = ?", c.ChannelId)

	query = query.Pluck("message_id", &messages)

	if err := query.Error; err != nil {
		return nil, err
	}

	parent := NewChannelMessage()
	channelMessages, err := parent.FetchByIds(messages)
	if err != nil {
		return nil, err
	}

	populatedChannelMessages, err := c.populateChannelMessages(channelMessages, q)
	if err != nil {
		return nil, err
	}

	return populatedChannelMessages, nil
}

func (c *ChannelMessageList) populateChannelMessages(channelMessages []ChannelMessage, query *Query) ([]*ChannelMessageContainer, error) {
	channelMessageCount := len(channelMessages)

	populatedChannelMessages := make([]*ChannelMessageContainer, channelMessageCount)

	if channelMessageCount == 0 {
		return populatedChannelMessages, nil
	}

	for i := 0; i < channelMessageCount; i++ {
		cm := channelMessages[i]
		cmc, err := cm.BuildMessage(query)
		if err != nil {
			return nil, err
		}

		populatedChannelMessages[i] = cmc
	}
	return populatedChannelMessages, nil

}

func (c *ChannelMessageList) FetchMessageChannels(messageId int64) ([]Channel, error) {
	var channelIds []int64

	q := &bongo.Query{
		Selector: map[string]interface{}{
			"message_id": messageId,
		},
		Pluck: "channel_id",
	}

	err := bongo.B.Some(c, &channelIds, q)
	if err != nil {
		return nil, err
	}

	return NewChannel().FetchByIds(channelIds)
}

func (c *ChannelMessageList) FetchMessageIdsByChannelId(channelId int64, q *Query) ([]int64, error) {
	query := &bongo.Query{
		Selector: map[string]interface{}{
			"channel_id": channelId,
		},
		Pluck: "message_id",
		Limit: q.Limit,
		Skip:  q.Skip,
		Sort: map[string]string{
			"added_at": "DESC",
		},
	}

	var messageIds []int64
	if err := c.Some(&messageIds, query); err != nil {
		return nil, err
	}

	if messageIds == nil {
		return make([]int64, 0), nil
	}

	return messageIds, nil
}

// seperate this fucntion into modelhelper
// as setting it to a variadic function
func (c *ChannelMessageList) DeleteMessagesBySelector(selector map[string]interface{}) error {
	var cmls []ChannelMessageList

	err := bongo.B.Some(c, &cmls, &bongo.Query{Selector: selector})
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
