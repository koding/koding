package paymentmodel

import "time"

type Plan struct {
	Id int64 `json:"id,string"`

	// Id of plan in 3rd payment provider like Stripe.
	ProviderPlanId string `json:"providerPlanId"`

	// Name of provider. Enum:
	//		'stripe', 'paypal'
	Provider string `json:"provider"`

	// Duration of subscription. Enum:
	//    'monthly', 'yearly'
	Interval string `json:"interval"`

	// Title of plan. Enum:
	//		'free', 'hobbyist', 'developer', 'professional'
	Title string `json:"title, string"`

	// Cost of plan in cents.
	AmountInCents uint64 `json:"cents"`

	// Timestamps.
	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt" `
	DeletedAt time.Time `json:"deletedAt"`
}

func NewPlan(name, providerId, provider string) *Plan {
	return &Plan{}
}
