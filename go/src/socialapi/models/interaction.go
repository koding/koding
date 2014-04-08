package models

import (
	"errors"
	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
	"time"
)

type Interaction struct {
	// unique identifier of the Interaction
	Id int64 `json:"id"`

	// Id of the interacted message
	MessageId int64 `json:"messageId"             sql:"NOT NULL"`

	// Id of the actor
	AccountId int64 `json:"accountId"             sql:"NOT NULL"`

	// Type of the interaction
	TypeConstant string `json:"typeConstant"      sql:"NOT NULL;TYPE:VARCHAR(100);"`

	// Creation of the interaction
	CreatedAt time.Time `json:"createdAt"         sql:"NOT NULL"`
}

var AllowedInteractions = map[string]struct{}{
	"like":     struct{}{},
	"upvote":   struct{}{},
	"downvote": struct{}{},
}

const (
	Interaction_TYPE_LIKE     = "like"
	Interaction_TYPE_UPVOTE   = "upvote"
	Interaction_TYPE_DONWVOTE = "downvote"
)

func (i *Interaction) GetId() int64 {
	return i.Id
}

func (i Interaction) TableName() string {
	return "api.interaction"
}

func NewInteraction() *Interaction {
	return &Interaction{}
}

func (i *Interaction) One(q *bongo.Query) error {
	return bongo.B.One(i, i, q)
}

func (i *Interaction) Fetch() error {
	return bongo.B.Fetch(i)
}

func (i *Interaction) Create() error {
	return bongo.B.Create(i)
}

func (i *Interaction) AfterCreate() {
	bongo.B.AfterCreate(i)
}

func (i *Interaction) AfterUpdate() {
	bongo.B.AfterUpdate(i)
}

func (i *Interaction) AfterDelete() {
	bongo.B.AfterDelete(i)
}

func (i *Interaction) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(i, data, q)
}

func (i *Interaction) Delete() error {
	if err := bongo.B.DB.
		Where("message_id = ? and account_id = ?", i.MessageId, i.AccountId).
		Delete(NewInteraction()).Error; err != nil {
		return err
	}
	return nil
}

func (c *Interaction) List(interactionType string) ([]int64, error) {
	var interactions []int64

	if c.MessageId == 0 {
		return interactions, errors.New("ChannelId is not set")
	}

	return c.FetchInteractorIds(&bongo.Pagination{})
}

func (i *Interaction) Some(data interface{}, q *bongo.Query) error {

	return bongo.B.Some(i, data, q)
}

func (i *Interaction) FetchInteractorIds(p *bongo.Pagination) ([]int64, error) {
	var interactorIds []int64
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"message_id": i.MessageId,
		},
		Pagination: *p,
		Pluck:      "account_id",
	}

	if err := i.Some(&interactorIds, q); err != nil {
		return nil, err
	}

	if interactorIds == nil {
		return make([]int64, 0), nil
	}

	return interactorIds, nil
}

func (c *Interaction) FetchAll(interactionType string) ([]Interaction, error) {
	var interactions []Interaction

	if c.MessageId == 0 {
		return interactions, errors.New("ChannelId is not set")
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
		return false, errors.New("Message Id is not set")
	}

	selector := map[string]interface{}{
		"message_id": i.MessageId,
		"account_id": accountId,
	}

	err := i.One(bongo.NewQS(selector))
	if err == nil {
		return true, nil
	}

	if err == gorm.RecordNotFound {
		return false, nil
	}

	return false, err
}

func (i *Interaction) FetchInteractorIdsWithCount(p *bongo.Pagination, count *int) ([]int64, error) {
	interactorIds, err := i.FetchInteractorIds(p)
	if err != nil {
		return nil, err
	}

	c, err := bongo.B.Count(i, "message_id = ?", i.MessageId)
	if err != nil {
		return nil, err
	}
	*count = c

	return interactorIds, nil
}
