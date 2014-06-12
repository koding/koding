package models

import (
	"errors"
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

func (i Interaction) GetId() int64 {
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

func (i *Interaction) ById(id int64) error {
	return bongo.B.ById(i, id)
}

func (i *Interaction) Create() error {
	return bongo.B.Create(i)
}

func (i *Interaction) CreateRaw() error {
	insertSql := "INSERT INTO " +
		i.TableName() +
		` ("message_id","account_id","type_constant","created_at") VALUES ($1,$2,$3,$4) ` +
		"RETURNING ID"

	return bongo.B.DB.CommonDB().
		QueryRow(insertSql, i.MessageId, i.AccountId, i.TypeConstant, i.CreatedAt).
		Scan(&i.Id)
}

func (i *Interaction) AfterCreate() {
	bongo.B.AfterCreate(i)
}

func (i *Interaction) AfterUpdate() {
	bongo.B.AfterUpdate(i)
}

func (i Interaction) AfterDelete() {
	bongo.B.AfterDelete(i)
}

func (i *Interaction) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(i, data, q)
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

func (c *Interaction) List(query *Query) ([]int64, error) {
	var interactions []int64

	if c.MessageId == 0 {
		return interactions, errors.New("Message is not set")
	}

	p := bongo.NewPagination(query.Limit, query.Skip)

	return c.FetchInteractorIds(query.Type, p)
}

func (i *Interaction) FetchInteractorIds(interactionType string, p *bongo.Pagination) ([]int64, error) {
	interactorIds := make([]int64, 0)
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"message_id":    i.MessageId,
			"type_constant": interactionType,
		},
		Pagination: *p,
		Pluck:      "account_id",
		Sort: map[string]string{
			"created_at": "desc",
		},
	}

	if err := i.Some(&interactorIds, q); err != nil {
		// TODO log this error
		return make([]int64, 0), nil
	}

	return interactorIds, nil
}

func (c *Interaction) Count(interactionType string) (int, error) {
	if c.MessageId == 0 {
		return 0, errors.New("MessageId is not set")
	}

	return bongo.B.Count(c,
		"message_id = ? and type_constant = ?",
		c.MessageId,
		interactionType,
	)
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

func (i *Interaction) FetchInteractorCount() (int, error) {
	return bongo.B.Count(i, "message_id = ?", i.MessageId)
}
