package models

import (
	"errors"
	"fmt"
	"socialapi/request"
	"time"

	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
)

type Interaction struct {
	// unique identifier of the Interaction
	Id int64 `json:"id,string"`

	// Id of the interacted message
	MessageId int64 `json:"messageId,string"      sql:"NOT NULL"`

	// Id of the actor
	AccountId int64 `json:"accountId,string"      sql:"NOT NULL"`

	// holds troll, unsafe, etc
	MetaBits MetaBits `json:"metaBits"`

	// Type of the interaction
	TypeConstant string `json:"typeConstant"      sql:"NOT NULL;TYPE:VARCHAR(100);"`

	// Creation of the interaction
	CreatedAt time.Time `json:"createdAt"         sql:"NOT NULL"`
}

var AllowedInteractions = map[string]struct{}{
	"like":     {},
	"upvote":   {},
	"downvote": {},
}

const (
	Interaction_TYPE_LIKE     = "like"
	Interaction_TYPE_UPVOTE   = "upvote"
	Interaction_TYPE_DONWVOTE = "downvote"
)

func (i *Interaction) ListLikedMessageIds(q *request.Query, channelId int64) ([]int64, error) {
	messageIds := make([]int64, 0)

	query := getLikedMessagesQuery(q, channelId)

	rows, err := query.Rows()
	defer rows.Close()
	if err != nil {
		return nil, err
	}
	if rows == nil {
		return messageIds, nil
	}

	var messageId int64
	for rows.Next() {
		rows.Scan(&messageId)
		messageIds = append(messageIds, messageId)
	}

	return messageIds, nil
}

func (i *Interaction) ListLikedMessages(q *request.Query, channelId int64) ([]ChannelMessage, error) {
	ids, err := i.ListLikedMessageIds(q, channelId)
	if err != nil {
		return nil, err
	}

	return NewChannelMessage().FetchByIds(ids)
}

func getLikedMessagesQuery(q *request.Query, channelId int64) *gorm.DB {
	i := NewInteraction()

	return bongo.B.DB.
		Model(i).
		Table(i.BongoName()).
		Limit(q.Limit).
		Offset(q.Skip).
		Select("api.interaction.message_id").
		Joins(
		`left join api.channel_message on
		 api.interaction.message_id = api.channel_message.id`).
		Where(
		`api.interaction.account_id = ? and
		 api.channel_message.initial_channel_id = ? and
		 api.channel_message.type_constant = ? and
		 api.interaction.type_constant = ? and
		 api.channel_message.meta_bits <> ?`,
		q.AccountId,
		channelId,
		ChannelMessage_TYPE_POST,
		q.Type,
		Troll,
	)
}

// Tests are done.
func (i *Interaction) MarkIfExempt() error {
	isExempt, err := i.isExempt()
	if err != nil {
		return err
	}

	if isExempt {
		i.MetaBits.Mark(Troll)
	}

	return nil
}

// Tests are done.
func (i *Interaction) isExempt() (bool, error) {
	if i.MetaBits.Is(Troll) {
		return true, nil
	}

	accountId, err := i.getAccountId()
	if err != nil {
		return false, err
	}

	account, err := ResetAccountCache(accountId)
	if err != nil {
		return false, err
	}

	if account == nil {
		return false, fmt.Errorf("account is nil, accountId:%d", i.AccountId)
	}

	if account.IsTroll {
		return true, nil
	}

	return false, nil
}

// Tests are done.
func (i *Interaction) getAccountId() (int64, error) {
	if i.AccountId != 0 {
		return i.AccountId, nil
	}

	if i.Id == 0 {
		return 0, fmt.Errorf("couldnt find accountId from content %+v", i)
	}

	ii := NewInteraction()
	if err := ii.ById(i.Id); err != nil {
		return 0, err
	}

	return ii.AccountId, nil
}

func (i *Interaction) Delete() error {
	selector := map[string]interface{}{
		"message_id": i.MessageId,
		"account_id": i.AccountId,
	}

	if err := i.One(bongo.NewQS(selector)); err != nil {
		return err
	}

	if err := bongo.B.Delete(i); err != nil {
		return err
	}

	return nil
}

func (i *Interaction) List(query *request.Query) ([]int64, error) {
	var interactions []int64

	if i.MessageId == 0 {
		return interactions, ErrMessageIdIsNotSet
	}

	return i.FetchInteractorIds(query)
}

func (i *Interaction) FetchInteractorIds(query *request.Query) ([]int64, error) {
	interactorIds := make([]int64, 0)
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"message_id":    i.MessageId,
			"type_constant": query.Type,
		},
		Pagination: *bongo.NewPagination(query.Limit, query.Skip),
		Pluck:      "account_id",
		Sort: map[string]string{
			"created_at": "desc",
		},
	}

	q.AddScope(RemoveTrollContent(i, query.ShowExempt))

	if err := i.Some(&interactorIds, q); err != nil {
		// TODO log this error
		return make([]int64, 0), nil
	}

	return interactorIds, nil
}

func (c *Interaction) Count(q *request.Query) (int, error) {
	if c.MessageId == 0 {
		return 0, ErrMessageIdIsNotSet
	}

	if q.Type == "" {
		return 0, errors.New("query type is not set")
	}

	query := &bongo.Query{
		Selector: map[string]interface{}{
			"message_id":    c.MessageId,
			"type_constant": q.Type,
		},
	}

	query.AddScope(RemoveTrollContent(
		c, q.ShowExempt,
	))

	i := NewInteraction()
	*i = *c
	i.Id = 0

	return i.CountWithQuery(query)
}

func (c *Interaction) CountWithQuery(q *bongo.Query) (int, error) {
	return bongo.B.CountWithQuery(c, q)
}

// this only used for while deleting the message, and its all required data
// do not use this for other purposes
func (c *Interaction) FetchAll(interactionType string) ([]Interaction, error) {
	var interactions []Interaction

	if c.MessageId == 0 {
		return interactions, errors.New("channelId is not set")
	}

	selector := map[string]interface{}{
		"message_id":    c.MessageId,
		"type_constant": interactionType,
	}

	err := c.Some(&interactions, bongo.NewQS(selector))
	if err != nil {
		return interactions, err
	}

	return interactions, nil
}

func (i *Interaction) IsInteracted(accountId int64) (bool, error) {
	if i.MessageId == 0 {
		return false, ErrMessageIdIsNotSet
	}

	if accountId == 0 {
		return false, nil
	}

	selector := map[string]interface{}{
		"message_id": i.MessageId,
		"account_id": accountId,
	}

	// do not set
	err := NewInteraction().One(bongo.NewQS(selector))
	if err == nil {
		return true, nil
	}

	if err == bongo.RecordNotFound {
		return false, nil
	}

	return false, err
}

func (i *Interaction) FetchInteractorCount() (int, error) {
	return bongo.B.Count(i, "message_id = ?", i.MessageId)
}

func (i *Interaction) FetchInteractionContainer(query *request.Query) (*InteractionContainer, error) {
	if i.MessageId == 0 {
		return nil, ErrMessageIdIsNotSet
	}

	interactorIds, err := i.List(query)
	if err != nil {
		return nil, err
	}

	oldIds, err := FetchOldIdsByAccountIds(interactorIds)
	if err != nil {
		return nil, err
	}

	interactionContainer := NewInteractionContainer()
	interactionContainer.ActorsPreview = oldIds

	if query.AddIsInteracted {
		// check if the current user is interacted in this thread
		isInteracted, err := i.IsInteracted(query.AccountId)
		if err != nil {
			return nil, err
		}

		interactionContainer.IsInteracted = isInteracted
	}

	// fetch interaction count
	count, err := i.Count(query)
	if err != nil {
		return nil, err
	}

	interactionContainer.ActorsCount = count

	return interactionContainer, nil
}
