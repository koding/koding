package paymentmodel

import (
	"time"
)

type Plan struct {
	Id int64 `json:"id,string"`

	// Id of plan in 3rd payment provider like Stripe.
	ProviderPlanId string `json:"providerPlanId"`

	// Name of provider. Enum: 'stripe'
	Provider string `json:"provider"`

	// Duration of subscription. Enum:
	//    'monthly', 'yearly'
	Interval string `json:"interval"`

	// Name of plan.
	Name string `json:"name, string"`

	// Name of plan and interval.
	Slug string `json:"slug, string"`

	// Cost of plan in cents.
	AmountInCents int `json:"cents"`

	// Timestamps.
	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt" `
	DeletedAt time.Time `json:"deletedAt"`
}

// func NewPlan(name, interval, provider string) *Plan {}

// func (p *Plan) Find() error   {}
// func (p *Plan) Create() error {}
