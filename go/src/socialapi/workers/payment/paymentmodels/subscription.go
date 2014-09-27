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
