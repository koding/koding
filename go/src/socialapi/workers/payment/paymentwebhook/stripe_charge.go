package main

import (
	"encoding/json"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
)

func stripePaymentRefunded(raw []byte, c *Controller) error {
	amountGetter := func(req *webhookmodels.StripeCharge) float64 {
		return req.AmountRefunded
	}

	return stripeChargeHelper(raw, c, PaymentRefunded, amountGetter)
}

func stripePaymentFailed(raw []byte, c *Controller) error {
	amountGetter := func(req *webhookmodels.StripeCharge) float64 {
		return req.Amount
	}

	return stripeChargeHelper(raw, c, PaymentFailed, amountGetter)
}

type amountGetterFn func(req *webhookmodels.StripeCharge) float64

func stripeChargeHelper(raw []byte, c *Controller, act Action, aFn amountGetterFn) error {
	var req *webhookmodels.StripeCharge

	err := json.Unmarshal(raw, &req)
	if err != nil {
		return err
	}

	user, err := getUserForCustomer(req.CustomerId)
	if err != nil {
		return err
	}

	amount := formatStripeAmount(req.Currency, aFn(req))
	opts := map[string]interface{}{"price": amount}

	Log.Info("Stripe: Sent invoice email to: %s", user.Email)

	return SendEmail(user, act, opts)
}
