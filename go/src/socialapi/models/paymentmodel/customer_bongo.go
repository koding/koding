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

var UsernameNotSet = errors.New("username not set")

func (c *Customer) ByUserName() (bool, error) {
	if c.Username == "" {
		return false, UsernameNotSet
	}

	selector := map[string]interface{}{"username": c.Username}

	err := c.One(bongo.NewQS(selector))
	if err == bongo.RecordNotFound {
		return false, nil
	}

	return true, nil
}
