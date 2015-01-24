package main

import (
	"encoding/json"
	"fmt"
	"koding/kodingemail"
	"socialapi/workers/payment/paymentemail"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
)

func stripeChargeRefunded(raw []byte, email *kodingemail.SG) error {
	return _stripeChargeHelper(raw, email, paymentemail.ChargeRefunded)
}

func stripeChargeFailed(raw []byte, email *kodingemail.SG) error {
	return _stripeChargeHelper(raw, email, paymentemail.ChargeFailed)
}

func _stripeChargeHelper(raw []byte, email *kodingemail.SG, action paymentemail.Action) error {
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
		"currency":       req.Currency,
		"amountRefunded": fmt.Sprintf("%v", req.Amount),
		"cardBrand":      req.Card.Brand,
		"cardLast4":      req.Card.Last4,
	}

	return paymentemail.Send(email, action, emailAddress, opts)
}
