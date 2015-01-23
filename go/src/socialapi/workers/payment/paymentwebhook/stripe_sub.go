package main

import (
	"encoding/json"
	"socialapi/workers/payment/paymentemail"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
	"socialapi/workers/payment/stripe"
)

type subscriptionActionType func(*webhookmodels.StripeSubscription) error

func stripeSubscriptionCreated(raw []byte) error {
	actions := []subscriptionActionType{
		sendSubscriptionCreatedEmail,
	}

	return _stripeSubscription(raw, actions)
}

func stripeSubscriptionDeleted(raw []byte) error {
	actions := []subscriptionActionType{
		stripe.SubscriptionDeletedWebhook,
		sendSubscriptionDeletedEmail,
	}

	return _stripeSubscription(raw, actions)
}

func _stripeSubscription(raw []byte, actions []subscriptionActionType) error {
	var req *webhookmodels.StripeSubscription

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

func sendSubscriptionCreatedEmail(req *webhookmodels.StripeSubscription) error {
	email, err := getEmailForCustomer(req.CustomerId)
	if err != nil {
		return err
	}

	opts := &paymentemail.Options{
		PlanName: req.Plan.Name,
	}

	return paymentemail.Send(paymentemail.SubscriptionCreated, email, opts)
}

func sendSubscriptionDeletedEmail(req *webhookmodels.StripeSubscription) error {
	email, err := getEmailForCustomer(req.CustomerId)
	if err != nil {
		return err
	}

	opts := &paymentemail.Options{
		PlanName: req.Plan.Name,
	}

	return paymentemail.Send(paymentemail.SubscriptionDeleted, email, opts)
}
