package paymentmodel

import "github.com/koding/bongo"

func (s Subscription) GetId() int64 {
	return s.Id
}

func (Subscription) TableName() string {
	return "api.payment_subscription"
}

//----------------------------------------------------------
// Crud methods
//----------------------------------------------------------

func (s *Subscription) One(q *bongo.Query) error {
	return bongo.B.One(s, s, q)
}

func (s *Subscription) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(s, data, q)
}

func (s *Subscription) Create() error {
	return bongo.B.Create(s)
}
