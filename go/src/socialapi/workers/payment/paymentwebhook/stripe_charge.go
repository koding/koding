package main

import (
	"encoding/json"
	"socialapi/workers/payment/paymentemail"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
)

func stripeChargeRefunded(raw []byte, c *Controller) error {
	return _stripeChargeHelper(raw, c, paymentemail.ChargeRefunded)
}

func stripeChargeFailed(raw []byte, c *Controller) error {
	return _stripeChargeHelper(raw, c, paymentemail.ChargeFailed)
}

func _stripeChargeHelper(raw []byte, c *Controller, action paymentemail.Action) error {
	var req *webhookmodels.StripeCharge

	err := json.Unmarshal(raw, &req)
	if err != nil {
		return err
	}

	emailAddress, err := getEmailForCustomer(req.CustomerId)
	if err != nil {
		return err
	}

	opts := map[string]string{
		"price": formatAmount(req.Amount, req.Currency),
	}

	return paymentemail.Send(c.Email, action, emailAddress, opts)
}
