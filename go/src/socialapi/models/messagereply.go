package models

import (
	"errors"
	"socialapi/request"
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

	// holds troll, unsafe, etc
	MetaBits MetaBits `json:"metaBits"`

	// Creation of the MessageReply
	CreatedAt time.Time `json:"createdAt"         sql:"NOT NULL"`

	// is required to identify to request in client side
	ClientRequestId string `json:"clientRequestId,omitempty" sql:"-"`
}

func (m *MessageReply) MarkIfExempt() error {
	if m.MetaBits.Is(Troll) {
		return nil
	}

	if m.ReplyId == 0 {
		return nil
	}

	cm := NewChannelMessage()
	cm.Id = m.ReplyId
	isExempt, err := cm.isExempt()
	if err != nil {
		return err
	}

	if isExempt {
		m.MetaBits.Mark(Troll)
	}

	return nil
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
	query := bongo.B.DB.Table(m.BongoName())
	query = query.Where("message_id = ? or reply_id = ?", messageId, messageId)

	if err := query.Find(&messageReplies).Error; err != bongo.RecordNotFound && err != nil {
		return err
	}

	if messageReplies == nil {
		return nil
	}

	if len(messageReplies) == 0 {
		return nil
	}

	for _, messageReply := range messageReplies {
		err := bongo.B.Delete(&messageReply)
		if err != nil {
			return err
		}
	}

	return nil
}

func (m *MessageReply) List(query *request.Query) ([]ChannelMessage, error) {
	return m.fetchMessages(query)
}

func (m *MessageReply) ListAll() ([]ChannelMessage, error) {
	query := request.NewQuery()
	query.Limit = 0
	query.Skip = 0
	return m.fetchMessages(query)
}

func (m *MessageReply) fetchMessages(query *request.Query) ([]ChannelMessage, error) {
	if m.MessageId == 0 {
		return nil, ErrMessageIdIsNotSet
	}

	q := &bongo.Query{
		Selector: map[string]interface{}{
			"message_id": m.MessageId,
		},
		Pluck:      "reply_id",
		Pagination: *bongo.NewPagination(query.Limit, query.Skip),
		Sort:       map[string]string{"created_at": "DESC"},
	}

	q.AddScope(RemoveTrollContent(m, query.ShowExempt))

	bongoQuery := bongo.B.BuildQuery(m, q)
	if !query.From.IsZero() {
		bongoQuery = bongoQuery.Where("created_at < ?", query.From)
	}

	var replies []int64
	if err := bongo.CheckErr(
		bongoQuery.Pluck(q.Pluck, &replies),
	); err != nil {
		return nil, err
	}

	parent := NewChannelMessage()
	channelMessageReplies, err := parent.FetchByIds(replies)
	if err != nil {
		return nil, err
	}

	return channelMessageReplies, nil
}

func (m *MessageReply) UnreadCount(messageId int64, addedAt time.Time, showExempt bool) (int, error) {
	if messageId == 0 {
		return 0, ErrMessageIdIsNotSet
	}

	if addedAt.IsZero() {
		return 0, ErrAddedAtIsNotSet
	}

	query := "message_id = ? and created_at > ?"

	if !showExempt {
		query += " and meta_bits = ?"
	} else {
		query += " and meta_bits >= ?"
	}

	var metaBits MetaBits
	return bongo.B.Count(
		m,
		query,
		messageId,
		addedAt.UTC().Format(time.RFC3339Nano),
		metaBits,
	)
}

func (m *MessageReply) Count(q *request.Query) (int, error) {
	if m.MessageId == 0 {
		return 0, ErrMessageIdIsNotSet
	}

	query := &bongo.Query{
		Selector: map[string]interface{}{
			"message_id": m.MessageId,
		},
	}

	query.AddScope(RemoveTrollContent(
		m, q.ShowExempt,
	))

	return m.CountWithQuery(query)
}

func (m *MessageReply) CountWithQuery(q *bongo.Query) (int, error) {
	return bongo.B.CountWithQuery(m, q)
}

func (m *MessageReply) FetchParent() (*ChannelMessage, error) {
	parent := NewChannelMessage()

	if m.MessageId != 0 {
		if err := parent.ById(m.MessageId); err != nil {
			return nil, err
		}

		return parent, nil
	}

	if m.ReplyId == 0 {
		return nil, errors.New("replyId is not set")
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

func (m *MessageReply) FetchReply() (*ChannelMessage, error) {
	reply := NewChannelMessage()

	replyId, err := m.getReplyId()
	if err != nil {
		return nil, err
	}

	if err := reply.ById(replyId); err != nil {
		return nil, err
	}

	return reply, nil
}

func (m *MessageReply) getReplyId() (int64, error) {
	if m.Id == 0 && m.ReplyId == 0 {
		return 0, errors.New("required ids are not set")
	}

	if m.ReplyId != 0 {
		return m.ReplyId, nil
	}

	if m.Id == 0 {
		// shouldnt come here
		return 0, errors.New("couldnt fetch replyId")
	}

	if err := m.ById(m.Id); err != nil {
		return 0, err
	}

	return m.ReplyId, nil
}
