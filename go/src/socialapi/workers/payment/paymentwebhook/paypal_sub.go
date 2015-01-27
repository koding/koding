package main

import (
	"socialapi/workers/payment/paymentemail"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
	"socialapi/workers/payment/paypal"

	"github.com/koding/kite"
)

func paypalSubscriptionCreated(req *webhookmodels.PaypalGenericWebhook, c *Controller) error {
	return subscriptionEmail(
		req.PayerId, req.Plan, paymentemail.SubscriptionCreated, c.Email,
	)
}

func paypalSubscriptionDeleted(req *webhookmodels.PaypalGenericWebhook, c *Controller) error {
	err := paypalExpireSubscription(req.PayerId, c.Kite)
	if err != nil {
		Log.Error(err.Error())
	}

	return subscriptionEmail(
		req.PayerId, req.Plan, paymentemail.SubscriptionDeleted, c.Email,
	)
}

func paypalExpireSubscription(customerId string, k *kite.Client) error {
	err := paypal.ExpireBasedOnPayment(customerId)
	if err != nil {
		return err
	}

	return stopMachinesForUser(customerId, k)
}
