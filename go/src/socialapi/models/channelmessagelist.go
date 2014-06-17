package models

import (
	"errors"
	"time"

	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
)

type ChannelMessageList struct {
	// unique identifier of the channel message list
	Id int64 `json:"id,string"`

	// Id of the channel
	ChannelId int64 `json:"channelId,string"     sql:"NOT NULL"`

	// Id of the message
	MessageId int64 `json:"messageId,string"     sql:"NOT NULL"`

	// holds troll, unsafe, etc
	MetaBits int16 `json:"-"`

	// Addition date of the message to the channel
	AddedAt time.Time `json:"addedAt"            sql:"NOT NULL"`
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

func (c *ChannelMessageList) Update() error {
	return bongo.B.Update(c)
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
		cp.LastSeenAt.UTC().Format(time.RFC3339),
	)
}

func (c *ChannelMessageList) Create() error {
	return bongo.B.Create(c)
}

func (c *ChannelMessageList) CreateRaw() error {
	insertSql := "INSERT INTO " +
		c.TableName() +
		` ("channel_id","message_id","added_at") VALUES ($1,$2,$3) ` +
		"RETURNING ID"

	return bongo.B.DB.CommonDB().
		QueryRow(insertSql, c.ChannelId, c.MessageId, c.AddedAt).
		Scan(&c.Id)
}

func (c *ChannelMessageList) Delete() error {
	return bongo.B.Delete(c)
}

func (c *ChannelMessageList) List(q *Query, populateUnreadCount bool) (*HistoryResponse, error) {
	messageList, err := c.getMessages(q)
	if err != nil {
		return nil, err
	}

	if populateUnreadCount {
		messageList = c.populateUnreadCount(messageList)
	}

	hr := NewHistoryResponse()
	hr.MessageList = messageList
	return hr, nil
}

// populateUnreadCount adds unread count into message containers
func (c *ChannelMessageList) populateUnreadCount(messageList []*ChannelMessageContainer) []*ChannelMessageContainer {
	channel := NewChannel()
	channel.Id = c.ChannelId

	for i, message := range messageList {
		cml, err := channel.FetchMessageList(message.Message.Id)
		if err != nil {
			// helper.MustGetLogger().Error(err.Error())
			continue
		}

		count, err := NewMessageReply().UnreadCount(cml.MessageId, cml.AddedAt)
		if err != nil {
			// helper.MustGetLogger().Error(err.Error())
			continue
		}
		messageList[i].UnreadRepliesCount = count
	}

	return messageList
}

func (c *ChannelMessageList) getMessages(q *Query) ([]*ChannelMessageContainer, error) {
	var messages []int64

	if c.ChannelId == 0 {
		return nil, errors.New("ChannelId is not set")
	}

	query := &bongo.Query{
		Selector: map[string]interface{}{
			"channel_id": c.ChannelId,
		},
		Pluck:      "message_id",
		Pagination: *bongo.NewPagination(q.Limit, q.Skip),
		Sort:       map[string]string{"added_at": "DESC"},
	}

	bongoQuery := bongo.B.BuildQuery(c, query)
	if !q.From.IsZero() {
		bongoQuery = bongoQuery.Where("added_at < ?", q.From)
	}

	if err := bongo.CheckErr(
		bongoQuery.Pluck(query.Pluck, &messages),
	); err != nil {
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

func (c *ChannelMessageList) IsInChannel(messageId, channelId int64) (bool, error) {
	if messageId == 0 || channelId == 0 {
		return false, errors.New("channelId/messageId is not set")
	}

	query := &bongo.Query{
		Selector: map[string]interface{}{
			"channel_id": channelId,
			"message_id": messageId,
		},
	}

	err := c.One(query)
	if err == nil {
		return true, nil
	}

	if err == gorm.RecordNotFound {
		return false, nil
	}

	return false, err
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

func (c *ChannelMessageList) FetchMessageChannelIds(messageId int64) ([]int64, error) {
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

	return channelIds, nil
}

func (c *ChannelMessageList) FetchMessageChannels(messageId int64) ([]Channel, error) {
	channelIds, err := c.FetchMessageChannelIds(messageId)
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
		Pluck:      "message_id",
		Pagination: *bongo.NewPagination(q.Limit, q.Skip),
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

func (c *ChannelMessageList) UpdateAddedAt(channelId, messageId int64) error {
	if messageId == 0 || channelId == 0 {
		return errors.New("channelId/messageId is not set")
	}

	query := &bongo.Query{
		Selector: map[string]interface{}{
			"channel_id": channelId,
			"message_id": messageId,
		},
	}

	err := c.One(query)
	if err != nil {
		return err
	}

	c.AddedAt = time.Now().UTC()
	return c.Update()
}
