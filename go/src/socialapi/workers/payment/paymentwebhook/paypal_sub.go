package main

import (
	"koding/kodingemail"
	"socialapi/workers/payment/paymentemail"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
	"socialapi/workers/payment/paypal"
)

func paypalSubscriptionCreated(req *webhookmodels.PaypalGenericWebhook, email *kodingemail.SG) error {
	return subscriptionEmail(
		req.PayerId, req.Plan, paymentemail.SubscriptionCreated, email,
	)
}

func paypalSubscriptionDeleted(req *webhookmodels.PaypalGenericWebhook, email *kodingemail.SG) error {
	err := paypal.ExpireSubscription(req.PayerId)
	if err != nil {
		return err
	}

	return subscriptionEmail(
		req.PayerId, req.Plan, paymentemail.SubscriptionDeleted, email,
	)
}
