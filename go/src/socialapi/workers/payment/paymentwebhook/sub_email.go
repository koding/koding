package main

import (
	"koding/kodingemail"
	"socialapi/workers/payment/paymentemail"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
)

func subscriptionEmail(customerProviderId, planName string, action paymentemail.Action, client *kodingemail.SG) error {
	email, err := getEmailForCustomer(customerProviderId)
	if err != nil {
		return err
	}

	opts := map[string]string{"planName": planName}

	return paymentemail.Send(client, action, email, opts)
}

//----------------------------------------------------------
// paypal
//----------------------------------------------------------

func paypalSubscriptionCreatedEmail(req *webhookmodels.PaypalGenericWebhook, client *kodingemail.SG) error {
	return subscriptionEmail(
		req.PayerId, req.Plan, paymentemail.SubscriptionCreated, client,
	)
}

func paypalSubscriptionDeletedEmail(req *webhookmodels.PaypalGenericWebhook, client *kodingemail.SG) error {
	return subscriptionEmail(
		req.PayerId, req.Plan, paymentemail.SubscriptionDeleted, client,
	)
}

//----------------------------------------------------------
// stripe
//----------------------------------------------------------

func stripeSubscriptionCreatedEmail(req *webhookmodels.StripeSubscription, client *kodingemail.SG) error {
	return subscriptionEmail(
		req.CustomerId, req.Plan.Name, paymentemail.SubscriptionCreated, client,
	)
}

func stripeSubscriptionDeletedEmail(req *webhookmodels.StripeSubscription, client *kodingemail.SG) error {
	return subscriptionEmail(
		req.CustomerId, req.Plan.Name, paymentemail.SubscriptionDeleted, client,
	)
}
