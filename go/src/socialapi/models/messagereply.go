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

func (m *MessageReply) Some(data interface{}, q *bongo.Query) error {

	return bongo.B.Some(m, data, q)
}

func (m *MessageReply) One(q *bongo.Query) error {

	return bongo.B.One(m, m, q)
}

func (m *MessageReply) List() ([]ChannelMessage, error) {
	var replies []int64

	if m.MessageId == 0 {
		return nil, errors.New("MessageId is not set")
	}

	// TODO change this with FetchReplyIds methods
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

func (m *MessageReply) FetchReplyIds(p *bongo.Pagination) ([]int64, error) {
	var replyIds []int64
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"message_id": m.MessageId,
		},
		Pagination: *p,
		Pluck: "reply_id",
		Sort: map[string]string{
     		"created_at": "desc",
    	},
	}
	if err := m.Some(&replyIds, q); err != nil {
		return nil, err
	}

	return replyIds, nil
}

func (m *MessageReply) FetchByReplyId() error {
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"reply_id": m.ReplyId,
		},
	}
	return m.One(q)
}

func (m *MessageReply) FetchFirstAccountReply(accountId int64) error {
	cm := NewChannelMessage()
	rows, err := bongo.B.DB.Raw("SELECT mr.reply_id, mr.created_at "+
		"FROM "+m.TableName()+" mr "+
		"LEFT JOIN "+cm.TableName()+" cm ON cm.id = mr.reply_id "+
		"WHERE cm.account_id = ? AND mr.message_id = ? "+
		"ORDER BY cm.created_at ASC "+
		"LIMIT 1", accountId, m.MessageId).Rows()

	// probably gorm.ErrNotFound error must be caught
	if err != nil {
		return err
	}
	if rows.Next() {
		// i could not handle it by selecting all columns
		rows.Scan(&m.ReplyId, &m.CreatedAt)
	}

	return nil
}
