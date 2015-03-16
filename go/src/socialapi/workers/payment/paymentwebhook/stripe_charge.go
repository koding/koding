package main

import (
	"encoding/json"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
)

func stripePaymentRefunded(raw []byte, c *Controller) error {
	return stripeChargeHelper(raw, c, PaymentRefunded)
}

func stripePaymentFailed(raw []byte, c *Controller) error {
	return stripeChargeHelper(raw, c, PaymentFailed)
}

func stripeChargeHelper(raw []byte, c *Controller, action Action) error {
	var req *webhookmodels.StripeCharge

	err := json.Unmarshal(raw, &req)
	if err != nil {
		return err
	}

	user, err := getUserForCustomer(req.CustomerId)
	if err != nil {
		return err
	}

	opts := map[string]string{
		"price": formatStripeAmount(req.Currency, req.Amount),
	}

	Log.Info("Stripe: Sent invoice email to: %s", user.Email)

	return Email(user, action, opts)
}
