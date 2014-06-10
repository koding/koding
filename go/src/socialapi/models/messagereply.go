package models

import (
	"errors"
	"time"

	"github.com/koding/bongo"
)

type MessageReply struct {
	// unique identifier of the MessageReply
	Id int64 `json:"id,string"`

	// Id of the interacted message
	MessageId int64 `json:"messageId,string"     sql:"NOT NULL"`

	// Id of the reply
	ReplyId int64 `json:"replyId,string"         sql:"NOT NULL"`

	// Creation of the MessageReply
	CreatedAt time.Time `json:"createdAt"         sql:"NOT NULL"`
}

func (m MessageReply) GetId() int64 {
	return m.Id
}

func (m MessageReply) TableName() string {
	return "api.message_reply"
}

func NewMessageReply() *MessageReply {
	return &MessageReply{}
}

func (m *MessageReply) AfterCreate() {
	bongo.B.AfterCreate(m)
}

func (m *MessageReply) AfterUpdate() {
	bongo.B.AfterUpdate(m)
}

func (m MessageReply) AfterDelete() {
	bongo.B.AfterDelete(m)
}

func (m *MessageReply) ById(id int64) error {
	return bongo.B.ById(m, id)
}

func (m *MessageReply) Create() error {
	return bongo.B.Create(m)
}

func (m *MessageReply) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(m, data, q)
}

func (m *MessageReply) One(q *bongo.Query) error {
	return bongo.B.One(m, m, q)
}

func (m *MessageReply) Delete() error {
	selector := map[string]interface{}{
		"message_id": m.MessageId,
		"reply_id":   m.ReplyId,
	}

	if err := m.One(bongo.NewQS(selector)); err != nil {
		return err
	}

	err := bongo.B.Delete(m)
	if err != nil {
		return err
	}

	return nil
}

func (m *MessageReply) DeleteByOrQuery(messageId int64) error {
	var messageReplies []MessageReply
	query := bongo.B.DB.Table(m.TableName())
	query = query.Where("message_id = ? or reply_id = ?", messageId, messageId)

	if err := query.Find(&messageReplies).Error; err != nil {
		return err
	}

	if messageReplies == nil {
		return nil
	}

	if len(messageReplies) == 0 {
		return nil
	}

	for _, messageReply := range messageReplies {
		err := bongo.B.Delete(messageReply)
		if err != nil {
			return err
		}
	}

	return nil
}

func (m *MessageReply) List(query *Query) ([]ChannelMessage, error) {
	return m.fetchMessages(query)
}

func (m *MessageReply) ListAll() ([]ChannelMessage, error) {
	query := NewQuery()
	query.Limit = 0
	query.Skip = 0
	return m.fetchMessages(query)
}

func (m *MessageReply) fetchMessages(query *Query) ([]ChannelMessage, error) {
	var replies []int64

	if m.MessageId == 0 {
		return nil, errors.New("MessageId is not set")
	}

	q := &bongo.Query{
		Selector: map[string]interface{}{
			"message_id": m.MessageId,
		},
		Pluck:      "reply_id",
		Pagination: *bongo.NewPagination(query.Limit, query.Skip),
		Sort:       map[string]string{"created_at": "DESC"},
	}

	bongoQuery := bongo.B.BuildQuery(m, q)
	if !query.From.IsZero() {
		bongoQuery = bongoQuery.Where("created_at < ?", query.From)
	}

	bongoQuery = bongoQuery.Pluck(q.Pluck, &replies)
	if err := bongoQuery.Error; err != nil {
		return nil, err
	}

	parent := NewChannelMessage()
	channelMessageReplies, err := parent.FetchByIds(replies)
	if err != nil {
		return nil, err
	}

	return channelMessageReplies, nil
}

func (m *MessageReply) UnreadCount(messageId int64, addedAt time.Time) (int, error) {
	if messageId == 0 {
		return 0, errors.New("MessageId is not set")
	}

	if addedAt.IsZero() {
		return 0, errors.New("Last seen at date is not valid - it is zero")
	}

	return bongo.B.Count(
		m,
		"message_id = ? and created_at > ?",
		messageId,
		addedAt.UTC().Format(time.RFC3339),
	)
}

func (m *MessageReply) Count() (int, error) {
	if m.MessageId == 0 {
		return 0, errors.New("MessageId is not set")
	}

	return bongo.B.Count(m,
		"message_id = ?",
		m.MessageId,
	)
}

func (m *MessageReply) FetchRepliedMessage() (*ChannelMessage, error) {
	parent := NewChannelMessage()

	if m.MessageId != 0 {
		if err := parent.ById(m.MessageId); err != nil {
			return nil, err
		}

		return parent, nil
	}

	if m.ReplyId == 0 {
		return nil, errors.New("ReplyId is not set")
	}

	q := &bongo.Query{
		Selector: map[string]interface{}{
			"reply_id": m.ReplyId,
		},
	}

	if err := m.One(q); err != nil {
		return nil, err
	}

	if err := parent.ById(m.MessageId); err != nil {
		return nil, err
	}

	return parent, nil
}
