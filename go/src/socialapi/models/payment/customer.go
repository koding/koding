package payment

import (
	"time"
)

type Customer struct {
	Id int64 `json:"id,string"`

	// Id of customer in 3rd payment provider like Stripe.
	ProviderCustomerId string `json:"providerPlanId"`

	// Name of provider. Enum:
	//    'stripe', 'paypal'
	Provider string `json:"provider"`

	// Timestamps.
	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt" `
}

// func NewCustomers(id int64, provider string) *Customer {}

// func (c *Customer) FindOrCreate() error {}
// func (c *Customer) Find() error         {}
// func (c *Customer) Create() error       {}
