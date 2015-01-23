package main

import (
	"encoding/json"
	"koding/kodingemail"
	"socialapi/workers/payment/paymentemail"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
	"socialapi/workers/payment/stripe"
)

type subscriptionActionType func(*webhookmodels.StripeSubscription, *kodingemail.SG) error

func stripeSubscriptionCreated(raw []byte, email *kodingemail.SG) error {
	actions := []subscriptionActionType{
		sendSubscriptionCreatedEmail,
	}

	return _stripeSubscription(raw, actions, email)
}

func stripeSubscriptionDeleted(raw []byte, email *kodingemail.SG) error {
	actions := []subscriptionActionType{
		stripe.SubscriptionDeletedWebhook,
		sendSubscriptionDeletedEmail,
	}

	return _stripeSubscription(raw, actions, email)
}

func _stripeSubscription(raw []byte, actions []subscriptionActionType, email *kodingemail.SG) error {
	var req *webhookmodels.StripeSubscription

	err := json.Unmarshal(raw, &req)
	if err != nil {
		return err
	}

	for _, action := range actions {
		err := action(req, email)
		if err != nil {
			return err
		}
	}

	return nil
}

func sendSubscriptionCreatedEmail(req *webhookmodels.StripeSubscription, client *kodingemail.SG) error {
	email, err := getEmailForCustomer(req.CustomerId)
	if err != nil {
		return err
	}

	opts := &paymentemail.Options{
		PlanName: req.Plan.Name,
	}

	return paymentemail.Send(client, paymentemail.SubscriptionCreated, email, opts)
}

func sendSubscriptionDeletedEmail(req *webhookmodels.StripeSubscription, client *kodingemail.SG) error {
	email, err := getEmailForCustomer(req.CustomerId)
	if err != nil {
		return err
	}

	opts := &paymentemail.Options{
		PlanName: req.Plan.Name,
	}

	return paymentemail.Send(client, paymentemail.SubscriptionDeleted, email, opts)
}
