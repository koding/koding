package main

import (
	"encoding/json"
	"fmt"
	"koding/kodingemail"
	"socialapi/workers/payment/paymentemail"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
	"socialapi/workers/payment/stripe"
)

type stripeInvoiceActionType func(*webhookmodels.StripeInvoice, *kodingemail.SG) error

func stripeInvoiceCreated(raw []byte, email *kodingemail.SG) error {
	actions := []stripeInvoiceActionType{
		stripe.InvoiceCreatedWebhook,
		sendInvoiceCreatedEmail,
	}

	var req *webhookmodels.StripeInvoice

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

func sendInvoiceCreatedEmail(req *webhookmodels.StripeInvoice, client *kodingemail.SG) error {
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

	opts := map[string]string{
		"amountDue": fmt.Sprintf("%v", req.AmountDue),
		"currency":  req.Currency,
		"planName":  planName,
	}

	return paymentemail.Send(client, paymentemail.SubscriptionDeleted, email, opts)
}
