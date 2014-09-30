package paymentmodel

import (
	"errors"

	"socialapi/workers/payment/paymenterrors"

	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
)

func (c Customer) GetId() int64 {
	return c.Id
}

func (Customer) TableName() string {
	return "payment.customer"
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

var (
	ErrOldIdNotSet = errors.New("old_id not set")
	ErrIdNotSet    = errors.New("id not set")
)

func NewCustomer() *Customer {
	return &Customer{}
}

func (c *Customer) FindByOldId(oldId string) error {
	selector := map[string]interface{}{"old_id": oldId}

	err := c.One(bongo.NewQS(selector))
	if err == gorm.RecordNotFound {
		return paymenterrors.ErrCustomerNotFound
	}

	return err
}

func (c *Customer) FindActiveSubscription() (*Subscription, error) {
	if c.Id == 0 {
		return nil, ErrIdNotSet
	}

	subscription := NewSubscription()
	err := subscription.ByCustomerIdAndState(c.Id, "active")
	if err != nil {
		return nil, err
	}

	return subscription, nil
}

func (c *Customer) Delete() error {
	return bongo.B.Delete(c)
}
