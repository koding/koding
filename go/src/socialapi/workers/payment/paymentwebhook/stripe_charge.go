package main

import (
	"encoding/json"
	"socialapi/workers/payment/paymentemail"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
)

type stripeChargeActionType func(*webhookmodels.StripeCharge) error

func stripeChargeRefunded(raw []byte) error {
	actions := []stripeChargeActionType{
		sendChargeRefundedEmail,
	}

	return _stripeCharge(raw, actions)
}

func stripeChargeFailed(raw []byte) error {
	actions := []stripeChargeActionType{
		sendChargeFailedEmail,
	}

	return _stripeCharge(raw, actions)
}

func _stripeCharge(raw []byte, actions []stripeChargeActionType) error {
	var req *webhookmodels.StripeCharge

	err := json.Unmarshal(raw, &req)
	if err != nil {
		return err
	}

	for _, action := range actions {
		err := action(req)
		if err != nil {
			return err
		}
	}

	return nil
}

func sendChargeRefundedEmail(req *webhookmodels.StripeCharge) error {
	email, opts, err := _chargeWebhook(req)
	if err != nil {
		return err
	}

	return paymentemail.Send(paymentemail.ChargeRefunded, email, opts)
}

func sendChargeFailedEmail(req *webhookmodels.StripeCharge) error {
	email, opts, err := _chargeWebhook(req)
	if err != nil {
		return err
	}

	return paymentemail.Send(paymentemail.ChargeFailed, email, opts)
}

func _chargeWebhook(req *webhookmodels.StripeCharge) (string, *paymentemail.Options, error) {
	email, err := getEmailForCustomer(req.CustomerId)
	if err != nil {
		return "", nil, err
	}

	opts := &paymentemail.Options{
		Currency:       req.Currency,
		AmountRefunded: req.Amount,
		CardBrand:      req.Card.Brand,
		CardLast4:      req.Card.Last4,
	}

	return email, opts, nil
}
