package main

import (
	"encoding/json"
	"fmt"
	"koding/kodingemail"
	"socialapi/workers/payment/paymentemail"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
	"socialapi/workers/payment/stripe"
)

func stripeInvoiceCreated(raw []byte, email *kodingemail.SG) error {
	var invoice *webhookmodels.StripeInvoice

	err := json.Unmarshal(raw, &invoice)
	if err != nil {
		return err
	}

	err = stripe.InvoiceCreatedWebhook(invoice)
	if err != nil {
		return err
	}

	return sendInvoiceCreatedEmail(invoice, email)
}

func sendInvoiceCreatedEmail(req *webhookmodels.StripeInvoice, email *kodingemail.SG) error {
	emailAddress, err := getEmailForCustomer(req.CustomerId)
	if err != nil {
		return err
	}

	if len(req.Lines.Data) < 0 {
		return fmt.Errorf(
			"Invoice: %s for %s has 0 line items", req.ID, req.CustomerId,
		)
	}

	opts := map[string]string{
		"amountDue": fmt.Sprintf("%v", req.AmountDue),
		"currency":  req.Currency,
		"planName":  req.Lines.Data[0].Plan.Name,
	}

	return paymentemail.Send(
		email, paymentemail.InvoiceCreated, emailAddress, opts,
	)
}
