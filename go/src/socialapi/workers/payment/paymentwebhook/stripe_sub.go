package main

import (
	"encoding/json"
	"koding/kodingemail"
	"socialapi/workers/payment/paymentemail"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
	"socialapi/workers/payment/stripe"
)

func stripeSubscriptionCreated(raw []byte, email *kodingemail.SG) error {
	sub, err := _stripeSubscription(raw)
	if err != nil {
		return err
	}

	return subscriptionEmail(
		sub.CustomerId, sub.Plan.Name, paymentemail.SubscriptionCreated, email,
	)
}

func stripeSubscriptionDeleted(raw []byte, email *kodingemail.SG) error {
	sub, err := _stripeSubscription(raw)
	if err != nil {
		return err
	}

	err = stripe.SubscriptionDeletedWebhook(sub)
	if err != nil {
		return err
	}

	return subscriptionEmail(
		sub.CustomerId, sub.Plan.Name, paymentemail.SubscriptionDeleted, email,
	)
}

func _stripeSubscription(raw []byte) (*webhookmodels.StripeSubscription, error) {
	var req *webhookmodels.StripeSubscription

	err := json.Unmarshal(raw, &req)
	if err != nil {
		return nil, err
	}

	return req, nil
}
