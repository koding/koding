package paymentmodels

import "github.com/koding/bongo"

func NewCustomer() *Customer {
	return &Customer{}
}

func (c Customer) GetId() int64 {
	return c.Id
}

func (Customer) BongoName() string {
	return "payment.customer"
}

func (c *Customer) Create() error {
	return bongo.B.Create(c)
}

func (c *Customer) One(q *bongo.Query) error {
	return bongo.B.One(c, c, q)
}

func (c *Customer) Delete() error {
	return bongo.B.Delete(c)
}

func (c *Customer) ById(id int64) error {
	selector := map[string]interface{}{"id": id}
	return c.One(bongo.NewQS(selector))
}
