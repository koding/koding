package paymentmodel

import (
	"time"
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
	AccountId int64 `json:"accountId,string"`

	// Plan the subscription belongs to, internal plan id.
	PlanId int64 `json:"planId,string"`

	// Name of plan with interval suffix.
	PlanSlug string `json:"planSlug"`

	// State of the subscription. Enum:
	//    'active', 'expired'
	State string `json:"state"`

	// Timestamps
	CreatedAt  time.Time `json:"createdAt"`
	UpdatedAt  time.Time `json:"updatedAt" `
	DeletedAt  time.Time `json:"deletedAt"`
	ExpiredAt  time.Time `json:"expiredAt"`
	CanceledAt time.Time `json:"canceled_at"`
}

// func NewSubscription(acc *Customer, plan *plan) *Subscription {}

// func (s *Subscription) Find() error   {}
// func (s *Subscription) Create() error {}
// func (s *Subscription) Delete() error {}
// func (s *Subscription) List() error   {}
