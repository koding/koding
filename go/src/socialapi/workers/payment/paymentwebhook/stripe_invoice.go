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
	planName, err := getNewPlanName(req)
	if err != nil {
		return err
	}

	opts := map[string]interface{}{
		"planName":  planName,
		"price":     formatStripeAmount(req.Currency, req.AmountDue),
		"amountDue": req.AmountDue,
	}

	return SendEmail(req.CustomerId, PaymentCreated, opts)
}

func getNewPlanName(req *webhookmodels.StripeInvoice) (string, error) {
	if req.Lines.Data == nil {
		return "", fmt.Errorf(
			"Invoice: %s for %s has nil line items", req.ID, req.CustomerId,
		)
	}

	if req.Lines.Count < 1 {
		return "", fmt.Errorf(
			"Invoice: %s for %s has 0 line items", req.ID, req.CustomerId,
		)
	}

	last := len(req.Lines.Data) - 1
	planName := req.Lines.Data[last].Plan.Name

	return planName, nil
}
