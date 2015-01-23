package main

import (
	"encoding/json"
	"fmt"
	"koding/kodingemail"
	"socialapi/workers/payment/paymentemail"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
)

type stripeChargeActionType func(*webhookmodels.StripeCharge, *kodingemail.SG) error

func stripeChargeRefunded(raw []byte, email *kodingemail.SG) error {
	actions := []stripeChargeActionType{
		sendChargeRefundedEmail,
	}

	return _stripeCharge(raw, actions, email)
}

func stripeChargeFailed(raw []byte, email *kodingemail.SG) error {
	actions := []stripeChargeActionType{
		sendChargeFailedEmail,
	}

	return _stripeCharge(raw, actions, email)
}

func _stripeCharge(raw []byte, actions []stripeChargeActionType, email *kodingemail.SG) error {
	var req *webhookmodels.StripeCharge

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

func sendChargeRefundedEmail(req *webhookmodels.StripeCharge, client *kodingemail.SG) error {
	email, opts, err := _chargeWebhook(req)
	if err != nil {
		return err
	}

	return paymentemail.Send(client, paymentemail.ChargeRefunded, email, opts)
}

func sendChargeFailedEmail(req *webhookmodels.StripeCharge, client *kodingemail.SG) error {
	email, opts, err := _chargeWebhook(req)
	if err != nil {
		return err
	}

	return paymentemail.Send(client, paymentemail.ChargeFailed, email, opts)
}

func _chargeWebhook(req *webhookmodels.StripeCharge) (string, map[string]string, error) {
	email, err := getEmailForCustomer(req.CustomerId)
	if err != nil {
		return "", nil, err
	}

	opts := map[string]string{
		"currency":       req.Currency,
		"amountRefunded": fmt.Sprintf("%v", req.Amount),
		"cardBrand":      req.Card.Brand,
		"cardLast4":      req.Card.Last4,
	}

	return email, opts, nil
}
