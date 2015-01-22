package main

import (
	"encoding/json"
	"socialapi/workers/payment/paymentemail"
)

func sendChargeRefundedEmail(raw []byte) error {
	email, opts, err := _chargeWebhook(raw)
	if err != nil {
		return err
	}

	return paymentemail.Send(paymentemail.ChargeRefunded, email, opts)
}

func sendChargeFailedEmail(raw []byte) error {
	email, opts, err := _chargeWebhook(raw)
	if err != nil {
		return err
	}

	return paymentemail.Send(paymentemail.ChargeRefunded, email, opts)
}

func _chargeWebhook(raw []byte) (string, *paymentemail.Options, error) {
	var req *stripeChargeRefundWebhookReq

	err := json.Unmarshal(raw, &req)
	if err != nil {
		return "", nil, err
	}

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
