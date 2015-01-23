package main

import (
	"encoding/json"
	"fmt"
	"socialapi/workers/payment/paymentemail"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
	"socialapi/workers/payment/stripe"
)

type stripeInvoiceActionType func(*webhookmodels.StripeInvoice) error

func stripeInvoiceCreated(raw []byte) error {
	actions := []stripeInvoiceActionType{
		stripe.InvoiceCreatedWebhook,
		// sendInvoiceCreatedEmail,
	}

	var req *webhookmodels.StripeInvoice

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

func sendInvoiceCreatedEmail(req *webhookmodels.StripeInvoice) error {
	email, err := getEmailForCustomer(req.CustomerId)
	if err != nil {
		return err
	}

	if len(req.Lines.Data) < 0 {
		return fmt.Errorf(
			"Invoice: %s for %s has 0 line items", req.ID, req.CustomerId,
		)
	}

	planName := req.Lines.Data[0].Plan.Name

	opts := &paymentemail.Options{
		AmountDue: req.AmountDue,
		Currency:  req.Currency,
		PlanName:  planName,
	}

	return paymentemail.Send(paymentemail.SubscriptionDeleted, email, opts)
}
