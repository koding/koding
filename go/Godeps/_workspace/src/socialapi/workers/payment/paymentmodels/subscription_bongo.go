package paymentmodels

import (
	"time"

	"github.com/koding/bongo"
)

func (s Subscription) GetId() int64 {
	return s.Id
}

func (Subscription) BongoName() string {
	return "payment.subscription"
}

//----------------------------------------------------------
// Crud methods
//----------------------------------------------------------

func NewSubscription() *Subscription {
	return &Subscription{}
}

func (s *Subscription) One(q *bongo.Query) error {
	return bongo.B.One(s, s, q)
}

func (s *Subscription) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(s, data, q)
}

func (s *Subscription) Create() error {
	return bongo.B.Create(s)
}

func (s *Subscription) BeforeUpdate() error {
	s.UpdatedAt = time.Now().UTC()
	return nil
}

func (s *Subscription) ById(id int64) error {
	selector := map[string]interface{}{"id": s.Id}
	return s.Find(selector)
}

func (s *Subscription) Find(selector map[string]interface{}) error {
	return s.One(bongo.NewQS(selector))
}

func (s *Subscription) Delete() error {
	return bongo.B.Delete(s)
}
