package payment

import (
	"errors"
	"socialapi/workers/payment/stripe"
)

var (
	ProviderNotFound       = errors.New("provider not found")
	ProviderNotImplemented = errors.New("provider not implemented")
)

type SubscriptionRequest struct {
	AccountId, Token, Email string
	Provider, Plan          string
}

func (s *SubscriptionRequest) Subscribe() (interface{}, error) {
	switch s.Provider {
	case "stripe":
		return nil, stripe.Subscribe(s.Token, s.AccountId, s.Email, s.Plan)
	case "paypal":
		return nil, ProviderNotImplemented
	default:
		return nil, ProviderNotFound
	}
}
