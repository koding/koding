package models

import (
	"errors"
	"time"

	"github.com/koding/bongo"
)

type MessageReply struct {
	// unique identifier of the MessageReply
	Id int64 `json:"id"`

	// Id of the interacted message
	MessageId int64 `json:"messageId"             sql:"NOT NULL"`

	// Id of the reply
	ReplyId int64 `json:"replyId"                 sql:"NOT NULL"`

	// Creation of the MessageReply
	CreatedAt time.Time `json:"createdAt"         sql:"NOT NULL"`
}

func (m *MessageReply) GetId() int64 {
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

func (m *MessageReply) AfterDelete() {
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

func (m *MessageReply) Delete() error {
	if err := bongo.B.DB.
		Where("message_id = ? and reply_id = ?", m.MessageId, m.ReplyId).
		Delete(m).Error; err != nil {
		return err
	}
	return nil
}

func (m *MessageReply) DeleteByOrQuery(messageId int64) error {
	if err := bongo.B.DB.
		Where("message_id = ? or reply_id = ?", messageId, messageId).
		Delete(m).Error; err != nil {
		return err
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
		Pluck: "reply_id",
		Skip:  query.Skip,
		Limit: query.Limit,
		Sort:  map[string]string{"created_at": "DESC"},
	}

	if err := m.Some(&replies, q); err != nil {
		return nil, err
	}

	parent := NewChannelMessage()
	channelMessageReplies, err := parent.FetchByIds(replies)
	if err != nil {
		return nil, err
	}

	return channelMessageReplies, nil
}
