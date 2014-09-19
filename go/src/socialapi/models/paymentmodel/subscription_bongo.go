package paymentmodel

import (
	"errors"
	"time"

	"github.com/koding/bongo"
)

func (s Subscription) GetId() int64 {
	return s.Id
}

func (Subscription) TableName() string {
	return "payment.subscription"
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

func (s *Subscription) BeforeUpdate() error {
	s.UpdatedAt = time.Now().UTC()
	return nil
}

var ErrUpdatingToSamePlan = errors.New("subscription already subscribed to that plan")

func (s *Subscription) UpdatePlan(planId int64, amountInCents uint64) error {
	if s.PlanId == planId {
		return ErrUpdatingToSamePlan
	}

	s.PlanId = planId
	s.AmountInCents = amountInCents

	err := bongo.B.Update(s)
	if err != nil {
		return err
	}

	return nil
}
