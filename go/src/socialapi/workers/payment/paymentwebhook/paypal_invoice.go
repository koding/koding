package main

import (
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
	"socialapi/workers/payment/paypal"
)

func paypalPaymentSucceeded(req *webhookmodels.PaypalGenericWebhook, c *Controller) error {
	err := paypal.UpdateCurrentPeriods(req.PayerId, req.PaymentDate.Time, req.NextPaymentDate.Time)
	if err != nil {
		return err
	}

	return paypalPaymentHelper(req, PaymentCreated, c)
}

func paypalPaymentFailed(req *webhookmodels.PaypalGenericWebhook, c *Controller) error {
	err := paypalExpireSubscription(req.PayerId, c.Kite)
	if err != nil {
		return err
	}

	return paypalPaymentHelper(req, PaymentFailed, c)
}

func paypalPaymentHelper(req *webhookmodels.PaypalGenericWebhook, action Action, c *Controller) error {
	opts := map[string]interface{}{
		"planName": req.Plan,
		"price":    formatPaypalAmount(req.Currency, req.Amount),
	}

	return SendEmail(req.PayerId, action, opts)
}
