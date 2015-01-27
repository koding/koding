package main

import (
	"encoding/json"
	"socialapi/workers/payment/paymentemail"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
	"socialapi/workers/payment/stripe"
)

func stripeSubscriptionCreated(raw []byte, c *Controller) error {
	sub, err := unmarshalSubscription(raw)
	if err != nil {
		return err
	}

	return subscriptionEmail(
		sub.CustomerId, sub.Plan.Name, paymentemail.SubscriptionCreated, c.Email,
	)
}

func stripeSubscriptionDeleted(raw []byte, c *Controller) error {
	sub, err := unmarshalSubscription(raw)
	if err != nil {
		return err
	}

	err = stopMachinesForUser(sub.CustomerId, c.Kite)
	if err != nil {
		Log.Error(err.Error())
	}

	err = stripe.SubscriptionDeletedWebhook(sub)
	if err != nil {
		return err
	}

	return subscriptionEmail(
		sub.CustomerId, sub.Plan.Name, paymentemail.SubscriptionDeleted, c.Email,
	)
}

func unmarshalSubscription(raw []byte) (*webhookmodels.StripeSubscription, error) {
	var req *webhookmodels.StripeSubscription

	err := json.Unmarshal(raw, &req)
	if err != nil {
		return nil, err
	}

	return req, nil
}
