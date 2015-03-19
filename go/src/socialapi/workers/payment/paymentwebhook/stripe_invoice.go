package main

import (
	"encoding/json"
	"fmt"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
	"socialapi/workers/payment/stripe"
)

func stripePaymentSucceeded(raw []byte, c *Controller) error {
	var invoice *webhookmodels.StripeInvoice

	err := json.Unmarshal(raw, &invoice)
	if err != nil {
		return err
	}

	err = stripe.InvoiceCreatedWebhook(invoice)
	if err != nil {
		return err
	}

	return stripePaymentSucceededEmail(invoice, c)
}

func stripePaymentSucceededEmail(req *webhookmodels.StripeInvoice, c *Controller) error {
	user, err := getUserForCustomer(req.CustomerId)
	if err != nil {
		return err
	}

	if req.Lines.Data == nil {
		return fmt.Errorf(
			"Invoice: %s for %s has nil line items", req.ID, req.CustomerId,
		)
	}

	if len(req.Lines.Data) < 0 {
		return fmt.Errorf(
			"Invoice: %s for %s has 0 line items", req.ID, req.CustomerId,
		)
	}

	planName := req.Lines.Data[0].Plan.Name
	opts := map[string]interface{}{
		"planName": planName,
		"price":    formatStripeAmount(req.Currency, req.AmountDue),
	}

	Log.Info("Stripe: Sent invoice email to: %s with plan: %s", user.Email, planName)

	return SendEmail(user, PaymentCreated, opts)
}
