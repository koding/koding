package main

import (
	"koding/kodingemail"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
	"socialapi/workers/payment/paypal"
)

func paypalSubscriptionCreated(req *webhookmodels.PaypalGenericWebhook, email *kodingemail.SG) error {
	return paypalSubscriptionCreatedEmail(req, email)
}

func paypalSubscriptionDeleted(req *webhookmodels.PaypalGenericWebhook, email *kodingemail.SG) error {
	err := paypal.ExpireSubscription(req.PayerId)
	if err != nil {
		return err
	}

	return paypalSubscriptionDeletedEmail(req, email)
}
