package paymentmodel

import (
	"errors"

	"github.com/koding/bongo"
)

func (c Customer) GetId() int64 {
	return c.Id
}

func (Customer) TableName() string {
	return "api.payment_customer"
}

//----------------------------------------------------------
// Crud methods
//----------------------------------------------------------

func (c *Customer) Create() error {
	return bongo.B.Create(c)
}

func (c *Customer) One(q *bongo.Query) error {
	return bongo.B.One(c, c, q)
}

func (c *Customer) ByOldId() (bool, error) {
	if c.OldId == "" {
		return false, ErrOldIdNotSet
	}

	selector := map[string]interface{}{"old_id": c.OldId}

	err := c.One(bongo.NewQS(selector))
	if err == bongo.RecordNotFound {
		return false, nil
	}

	return true, nil
}

func (c *Customer) FindActiveSubscriptions() ([]*Subscription, error) {
	return nil, nil
}

var ErrOldIdNotSet = errors.New("old_id not set")
