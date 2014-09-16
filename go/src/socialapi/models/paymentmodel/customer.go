package paymentmodel

import (
	"time"
)

type Customer struct {
	Id int64 `json:"id,string"`

	OldId string `json:"oldId"`

	// Id of customer in 3rd payment provider like Stripe.
	ProviderCustomerId string `json:"providerCustomerId"`

	// Name of provider. Enum:
	//    'stripe', 'paypal'
	Provider string `json:"provider"`

	// Timestamps.
	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt" `
}

func NewCustomer(oldId, providerId, provider string) *Customer {
	return &Customer{
		OldId:              oldId,
		ProviderCustomerId: providerId,
		Provider:           provider,
	}
}
