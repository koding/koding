package models

import (
	"socialapi/request"
	"sync"
	"time"

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
	MetaBits MetaBits `json:"metaBits"`

	// Addition date of the message to the channel
	// this date will be update whever message added/removed/re-added to the channel
	AddedAt time.Time `json:"addedAt"            sql:"NOT NULL"`

	// Update time of the message/list
	RevisedAt time.Time `json:"revisedAt"        sql:"NOT NULL"`

	// Deletion date of the channel
	DeletedAt time.Time `json:"deletedAt"`

	// is required to identify to request in client side
	ClientRequestId string `json:"clientRequestId,omitempty" sql:"-"`
}

// Tests are done.
func (c *ChannelMessageList) UnreadCount(cp *ChannelParticipant) (int, error) {
	if cp.ChannelId == 0 {
		return 0, ErrChannelIdIsNotSet
	}

	if cp.AccountId == 0 {
		return 0, ErrAccountIdIsNotSet
	}

	if cp.LastSeenAt.IsZero() {
		return 0, ErrLastSeenAtIsNotSet
	}

	// checks if channel participant is a troll, if so we show all messages
	isExempt, err := cp.isExempt()
	if err != nil {
		return 0, err
	}

	query := "channel_id = ? and added_at > ?"

	if isExempt {
		query += " and meta_bits >= ?"
	} else {
		query += " and meta_bits = ?"
	}

	var metaBits MetaBits
	return bongo.B.Count(c,
		query,
		cp.ChannelId,
		// todo change this format to get from a specific place
		cp.LastSeenAt.UTC().Format(time.RFC3339Nano),
		metaBits,
	)
}

func (c *ChannelMessageList) List(q *request.Query, populateUnreadCount bool) (*HistoryResponse, error) {
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
			// runner.MustGetLogger().Error(err.Error())
			continue
		}

		count, err := NewMessageReply().UnreadCount(cml.MessageId, cml.RevisedAt, cml.MetaBits.Is(Troll))
		if err != nil {
			// runner.MustGetLogger().Error(err.Error())
			continue
		}
		messageList[i].UnreadRepliesCount = count
	}

	return messageList
}

func (c *ChannelMessageList) getMessages(q *request.Query) ([]*ChannelMessageContainer, error) {
	if c.ChannelId == 0 {
		return nil, ErrChannelIdIsNotSet
	}

	query := &bongo.Query{
		Selector: map[string]interface{}{
			"channel_id": c.ChannelId,
		},
		Pluck:      "message_id",
		Pagination: *bongo.NewPagination(q.Limit, q.Skip),
	}

	query.AddScope(RemoveTrollContent(c, q.ShowExempt))
	if q.SortOrder == "ASC" {
		query.AddScope(SortedByAddedAtASC)
	} else {
		query.AddScope(SortedByAddedAt)
	}

	bongoQuery := bongo.B.BuildQuery(c, query)

	if !q.From.IsZero() {
		if q.SortOrder == "ASC" {
			bongoQuery = bongoQuery.Where("added_at > ?", q.From)
		} else {
			bongoQuery = bongoQuery.Where("added_at < ?", q.From)
		}
	}

	var messages []int64
	if err := bongo.CheckErr(
		bongoQuery.Pluck(query.Pluck, &messages),
	); err != nil {
		return nil, err
	}

	populatedChannelMessages, err := c.PopulateChannelMessages(messages, q)
	if err != nil {
		return nil, err
	}

	return populatedChannelMessages, nil
}

// Tests are done.
func (c *ChannelMessageList) IsInChannel(messageId, channelId int64) (bool, error) {
	if messageId == 0 || channelId == 0 {
		return false, ErrChannelOrMessageIdIsNotSet
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

	if err == bongo.RecordNotFound {
		return false, nil
	}

	return false, err
}

func (c *ChannelMessageList) PopulateChannelMessages(channelMessageIds []int64, query *request.Query) ([]*ChannelMessageContainer, error) {
	channelMessageCount := len(channelMessageIds)

	populatedChannelMessages := make([]*ChannelMessageContainer, channelMessageCount)

	if channelMessageCount == 0 {
		return populatedChannelMessages, nil
	}

	var wg sync.WaitGroup
	var mu sync.Mutex
	var processErr error

	for i := 0; i < channelMessageCount; i++ {
		wg.Add(1)

		go func(i int) {
			defer wg.Done()
			cm := NewChannelMessage()
			cm.Id = channelMessageIds[i]
			cmc, err := cm.BuildMessage(query)
			if err != nil {
				mu.Lock()
				processErr = err
				mu.Unlock()
				return
			}

			mu.Lock()
			populatedChannelMessages[i] = cmc
			mu.Unlock()
		}(i)
	}

	wg.Wait()

	if processErr != nil {
		return nil, processErr
	}

	return populatedChannelMessages, nil
}

// To be continued. for tests.
func (c *ChannelMessageList) FetchMessageChannelIds(messageId int64) ([]int64, error) {
	if messageId == 0 {
		return nil, ErrMessageIdIsNotSet
	}

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

// FetchMessageChannels fetchs the channels by message id
//
// Tests are done.
func (c *ChannelMessageList) FetchMessageChannels(messageId int64) ([]Channel, error) {
	channelIds, err := c.FetchMessageChannelIds(messageId)
	if err != nil {
		return nil, err
	}

	return NewChannel().FetchByIds(channelIds)
}

// FetchMessageIdsByChannelId fetchs the channels by message id
func (c *ChannelMessageList) FetchMessageIdsByChannelId(channelId int64, q *request.Query) ([]int64, error) {
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

	// remove troll content
	query.AddScope(RemoveTrollContent(c, q.ShowExempt))

	var messageIds []int64
	if err := c.Some(&messageIds, query); err != nil {
		return nil, err
	}

	if messageIds == nil {
		return make([]int64, 0), nil
	}

	return messageIds, nil
}

// separate this function into modelhelper
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

// Tests are done.
func (c *ChannelMessageList) UpdateAddedAt(channelId, messageId int64) error {
	if messageId == 0 || channelId == 0 {
		return ErrChannelOrMessageIdIsNotSet
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

// Tests are done.
func (c *ChannelMessageList) MarkIfExempt() error {
	isExempt, err := c.isExempt()
	if err != nil {
		return err
	}

	if isExempt {
		c.MetaBits.Mark(Troll)
	}

	return nil
}

// Tests are done.
func (c *ChannelMessageList) isExempt() (bool, error) {
	// return early if channel is already exempt
	if c.MetaBits.Is(Troll) {
		return true, nil
	}

	if c.MessageId == 0 {
		return false, ErrMessageIdIsNotSet
	}

	cm := NewChannelMessage()
	cm.Id = c.MessageId

	return cm.isExempt()
}

// Count counts messages in the channel
// if account of message is troll, will not be counted as message
//
// Tests are done.
func (c *ChannelMessageList) Count(channelId int64) (int, error) {
	if channelId == 0 {
		return 0, ErrChannelIdIsNotSet
	}

	query := &bongo.Query{
		Selector: map[string]interface{}{
			"channel_id": channelId,
		},
	}

	query.AddScope(RemoveTrollContent(
		// dont show trolls
		c, false,
	))

	return c.CountWithQuery(query)
}

// this glance can cause problems..
func (c *ChannelMessageList) Glance() error {
	// why we are aggin one second?
	c.RevisedAt = time.Now().Add((time.Second * 1)).UTC()

	if err := c.Update(); err != nil {
		return err
	}

	return nil
}
