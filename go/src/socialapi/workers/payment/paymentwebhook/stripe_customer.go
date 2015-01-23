package main

import (
	"encoding/json"
	"koding/kodingemail"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
	"socialapi/workers/payment/stripe"
)

type stripeCustomerActionType func(*webhookmodels.StripeCustomer) error

func stripeCustomerDeleted(raw []byte, email *kodingemail.SG) error {
	actions := []stripeCustomerActionType{
		stripe.CustomerDeletedWebhook,
	}

	var req *webhookmodels.StripeCustomer

	err := json.Unmarshal(raw, &req)
	if err != nil {
		return err
	}

	for _, action := range actions {
		err := action(req)
		if err != nil {
			return err
		}
	}

	return nil
}
