package main

import (
	"socialapi/workers/payment/paymentemail"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
)

func paypalPaymentSucceeded(req *webhookmodels.PaypalGenericWebhook, c *Controller) error {
	return _paypalPaymentHelper(req, paymentemail.InvoiceCreated, c)
}

func paypalPaymentFailed(req *webhookmodels.PaypalGenericWebhook, c *Controller) error {
	err := paypalExpireSubscription(req.PayerId, c.Kite)
	if err != nil {
		return err
	}

	return _paypalPaymentHelper(req, paymentemail.ChargeFailed, c)
}

func _paypalPaymentHelper(req *webhookmodels.PaypalGenericWebhook, action paymentemail.Action, c *Controller) error {
	opts := map[string]string{
		"price": formatPaypalAmount(req.Currency, req.Amount),
	}

	emailAddress, err := getEmailForCustomer(req.PayerId)
	if err != nil {
		return err
	}

	return paymentemail.Send(c.Email, action, emailAddress, opts)
}
