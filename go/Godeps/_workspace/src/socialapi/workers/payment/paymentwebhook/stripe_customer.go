package main

import (
	"encoding/json"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
	"socialapi/workers/payment/stripe"
)

func stripeCustomerDeleted(raw []byte, _ *Controller) error {
	var customer *webhookmodels.StripeCustomer

	err := json.Unmarshal(raw, &customer)
	if err != nil {
		return err
	}

	return stripe.CustomerDeletedWebhook(customer)
}
