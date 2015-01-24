package main

import (
	"encoding/json"
	"koding/kodingemail"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
	"socialapi/workers/payment/stripe"
)

func stripeCustomerDeleted(raw []byte, _ *kodingemail.SG) error {
	var customer *webhookmodels.StripeCustomer

	err := json.Unmarshal(raw, &customer)
	if err != nil {
		return err
	}

	return stripe.CustomerDeletedWebhook(customer)
}
