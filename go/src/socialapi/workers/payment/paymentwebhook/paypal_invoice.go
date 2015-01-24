package main

import (
	"koding/kodingemail"
	"socialapi/workers/payment/paymentemail"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
)

func paypalPaymentSucceeded(req *webhookmodels.PaypalGenericWebhook, email *kodingemail.SG) error {
	return _paypalPaymentHelper(req, paymentemail.InvoiceCreated, email)
}

func paypalPaymentFailed(req *webhookmodels.PaypalGenericWebhook, email *kodingemail.SG) error {
	err := paypalExpireSubscription(req.PayerId)
	if err != nil {
		return err
	}

	return _paypalPaymentHelper(req, paymentemail.ChargeFailed, email)
}

func _paypalPaymentHelper(req *webhookmodels.PaypalGenericWebhook, action paymentemail.Action, email *kodingemail.SG) error {
	opts := map[string]string{
		"amount":   req.Amount,
		"currency": req.CurrencyCode,
	}

	emailAddress, err := getEmailForCustomer(req.PayerId)
	if err != nil {
		return err
	}

	return paymentemail.Send(email, action, emailAddress, opts)
}
