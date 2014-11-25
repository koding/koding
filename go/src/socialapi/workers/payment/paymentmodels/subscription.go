package paymentmodels

import (
	"fmt"
	"socialapi/workers/payment/paymenterrors"
	"time"

	"github.com/koding/bongo"
)

type Subscription struct {
	Id int64 `json:"id,string"`

	// Id of subscription in 3rd payment provider like Stripe.
	ProviderSubscriptionId string `json:"providerSubscriptionId"`

	// Name of provider. Enum:
	//    'stripe', 'paypal'
	Provider string `json:"provider"`

	// Token that was fetched from provider from client after successful
	// credit card validation, which is then used to identify the user.
	ProviderToken string `json:"providerToken"`

	// Account the subscription belongs to, internal account id.
	CustomerId int64 `json:"customerId,string"`

	// Plan the subscription belongs to, internal plan id.
	PlanId int64 `json:"planId,string"`

	// State of the subscription. Enum:
	//    'active', 'expired'
	State string `json:"state"`

	// Cost of plan in cents.
	AmountInCents uint64 `json:"amountInCents"`

	// Timestamps
	CreatedAt          time.Time `json:"createdAt"`
	UpdatedAt          time.Time `json:"updatedAt" `
	ExpiredAt          time.Time `json:"expiredAt"`
	CanceledAt         time.Time `json:"canceled_at"`
	CurrentPeriodStart time.Time `json:"current_period_start"`
	CurrentPeriodEnd   time.Time `json:"current_period_end"`
}

var (
	SubscriptionStateActive = "active"

	// this is when user manually cancels
	SubscriptionStateCanceled = "canceled"

	// this is when user fails to pay
	SubscriptionStateExpired = "expired"
)

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

	err := bongo.B.Update(s)

	return err
}

func (s *Subscription) UpdateState(state string) error {
	s.State = state
	err := bongo.B.Update(s)

	return err
}

func (s *Subscription) Cancel() error {
	err := s.Delete()
	if err != nil {
		return err
	}

	customer := NewCustomer()
	err = customer.ById(s.CustomerId)
	if err != nil {
		return err
	}

	subscriptions, err := customer.FindSubscriptions()
	if err != nil {
		return err
	}

	for _, subscription := range subscriptions {
		err := subscription.Delete()
		if err != nil {
			fmt.Println("Deleting user: %s subscription: %s failed: %v", customer.Username, subscription.Id, err)
		}
	}

	return customer.Delete()
}

func (s *Subscription) UpdateTimeForDowngrade(t time.Time) error {
	s.CanceledAt = t
	err := bongo.B.Update(s)

	return err
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

func (s *Subscription) ByCanceledAtGte(t time.Time) ([]Subscription, error) {
	subscriptions := []Subscription{}

	err := bongo.B.DB.
		Table(s.BongoName()).
		Where(
		"canceled_at > ?", t,
	).Find(&subscriptions).Error

	return subscriptions, err
}
