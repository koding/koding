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

func (m *MessageReply) TableName() string {
	return "message_reply"
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

func (m *MessageReply) Fetch() error {
	return bongo.B.Fetch(m)
}

func (m *MessageReply) Create() error {
	return bongo.B.Create(m)
}

func (m *MessageReply) Delete() error {
	if err := bongo.B.DB.
		Where("message_id = ? and reply_id = ?", m.MessageId, m.ReplyId).
		Delete(m).Error; err != nil {
		return err
	}
	return nil
}

func (m *MessageReply) List() ([]ChannelMessage, error) {
	var replies []int64

	if m.MessageId == 0 {
		return nil, errors.New("MessageId is not set")
	}

	if err := bongo.B.DB.Table(m.TableName()).
		Where("message_id = ?", m.MessageId).
		Pluck("reply_id", &replies).
		Error; err != nil {
		return nil, err
	}

	parent := NewChannelMessage()
	channelMessageReplies, err := parent.FetchByIds(replies)
	if err != nil {
		return nil, err
	}

	return channelMessageReplies, nil
}
