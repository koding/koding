package main

import (
	"encoding/json"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
)

func stripePaymentRefunded(raw []byte, c *Controller) error {
	amountGetter := func(req *webhookmodels.StripeCharge) string {
		return formatStripeAmount(req.Currency, req.AmountRefunded)
	}

	return stripeChargeHelper(raw, c, PaymentRefunded, amountGetter)
}

func stripePaymentFailed(raw []byte, c *Controller) error {
	amountGetter := func(req *webhookmodels.StripeCharge) string {
		return formatStripeAmount(req.Currency, req.Amount)
	}

	return stripeChargeHelper(raw, c, PaymentFailed, amountGetter)
}

type amountGetterFn func(req *webhookmodels.StripeCharge) string

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

	opts := map[string]interface{}{"price": aFn(req)}

	Log.Info("Stripe: Sent invoice email to: %s", user.Email)

	return SendEmail(user, act, opts)
}
