package paymentmodel

import (
	"errors"
	"socialapi/workers/payment/paymenterrors"
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

func (s *Subscription) UpdateInvoiceCreated(amountInCents uint64, planId, periodStart, periodEnd int64) error {
	if s.PlanId == planId {
		return ErrUpdatingToSamePlan
	}

	s.PlanId = planId
	s.AmountInCents = amountInCents
	s.CurrentPeriodStart = time.Unix(periodStart, 0)
	s.CurrentPeriodEnd = time.Unix(periodEnd, 0)

	// when user downgrades to non-free plan, we set `CanceledAt` till the
	// end of billing cycle and when `invoice.created` is fired we update
	// null this field
	s.CanceledAt = time.Time{}

	return bongo.B.Update(s)
}

func (s *Subscription) UpdatePlan(planId int64, amountInCents uint64) error {
	if s.PlanId == planId {
		return ErrUpdatingToSamePlan
	}

	s.PlanId = planId
	s.AmountInCents = amountInCents

	return bongo.B.Update(s)
}

func (s *Subscription) UpdateState(state string) error {
	s.State = state

	err := bongo.B.Update(s)
	if err != nil {
		return err
	}

	return nil
}

func (s *Subscription) UpdateTimeForDowngrade(t time.Time) error {
	s.CanceledAt = t

	err := bongo.B.Update(s)
	if err != nil {
		return err
	}

	return nil
}

var (
	ErrProviderSubscriptionIdNotSet = errors.New("provider_subscription_id is not set")
	ErrProviderNotSet               = errors.New("provider is not set")
	ErrIdNotset                     = errors.New("id is not set")
)

func NewSubscription() *Subscription {
	return &Subscription{}
}

func (s *Subscription) ById(id int64) error {
	selector := map[string]interface{}{"id": s.Id}
	err := s.One(bongo.NewQS(selector))
	if err != nil {
		return err
	}

	return nil
}

func (s *Subscription) ByProviderId(providerId, provider string) error {
	selector := map[string]interface{}{
		"provider_subscription_id": providerId,
		"provider":                 provider,
	}

	err := s.Find(selector)
	return err
}

func (s *Subscription) ByCustomerIdAndState(customerId int64, state string) error {
	selector := map[string]interface{}{
		"customer_id": customerId,
		"state":       state,
	}

	err := s.Find(selector)
	if err == bongo.RecordNotFound {
		return paymenterrors.ErrCustomerNotSubscribedToAnyPlans
	}

	return err
}

func (s *Subscription) Find(selector map[string]interface{}) error {
	err := s.One(bongo.NewQS(selector))
	return err
}

func (s *Subscription) ByCanceledAtGte(t time.Time) ([]*Subscription, error) {
	subscriptions := []*Subscription{}

	err := bongo.B.DB.
		Table(s.TableName()).
		Where(
		"canceled_at > ", t,
	).Find(&subscriptions).Error

	return subscriptions, err
}
