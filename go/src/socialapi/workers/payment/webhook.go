package payment

import (
	"encoding/json"
	"errors"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/email/emailsender"

	"github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/customer"
)

var mailSender = emailsender.Send

type StripeHandler func([]byte) error

var stripeActions = map[string]StripeHandler{
	"charge.succeeded": chargeSucceededHandler,
	"charge.failed":    chargeFailedHandler,

	"customer.subscription.created":        customerSubscriptionCreatedHandler,
	"customer.subscription.deleted":        customerSubscriptionDeletedHandler,
	"customer.subscription.updated":        customerSubscriptionUpdatedHandler,
	"customer.subscription.trial_will_end": customerSubscriptionTrialWillEndHandler,

	"invoice.created":           invoiceCreatedHandler,
	"invoice.payment_failed":    invoicePaymentFailedHandler,
	"invoice.payment_succeeded": invoicePaymentFailedHandler,
}

func GetHandler(name string) (StripeHandler, error) {
	action, ok := stripeActions[name]
	if ok {
		return action, nil
	}

	return nil, errors.New("handler not found")
}

func formatCurrency(currencyStr string, amount uint64) string {
	switch currencyStr {
	case "USD", "usd":
		currencyStr = "$"
	default:
		return ""
	}

	return fmt.Sprintf("%s%v", currencyStr, amount/100)
}

func chargeSucceededHandler(raw []byte) error {
	var charge *stripe.Charge
	err := json.Unmarshal(raw, &charge)
	if err != nil {
		return err
	}

	opts := getAmountOpts(charge)
	eventName := "charge succeeded"

	return sendEventForCustomer(charge.Customer.ID, eventName, opts)
}

func chargeFailedHandler(raw []byte) error {
	var charge *stripe.Charge
	err := json.Unmarshal(raw, &charge)
	if err != nil {
		return err
	}

	opts := getAmountOpts(charge)
	eventName := "charge failed"

	return sendEventForCustomer(charge.Customer.ID, eventName, opts)
}

func getAmountOpts(charge *stripe.Charge) map[string]interface{} {
	amount := formatCurrency(string(charge.Currency), charge.Amount)
	return map[string]interface{}{"amount": amount}
}

func customerSubscriptionCreatedHandler(raw []byte) error {
	var req *stripe.Sub
	err := json.Unmarshal(raw, &req)
	if err != nil {
		return err
	}

	eventName := fmt.Sprintf("subscribed to %s plan", req.Plan.ID)

	return sendEventForCustomer(req.Customer.ID, eventName, nil)
}

func customerSubscriptionDeletedHandler(raw []byte) error {
	var req *stripe.Sub
	err := json.Unmarshal(raw, &req)
	if err != nil {
		return err
	}

	eventName := fmt.Sprintf("unsubscribed from %s plan", req.Plan.ID)

	return sendEventForCustomer(req.Customer.ID, eventName, nil)
}

func customerSubscriptionUpdatedHandler(raw []byte) error {
	var req *stripe.Sub
	err := json.Unmarshal(raw, &req)
	if err != nil {
		return err
	}

	eventName := fmt.Sprintf("subscription of %s plan updated", req.Plan.ID)

	return sendEventForCustomer(req.Customer.ID, eventName, nil)
}

func customerSubscriptionTrialWillEndHandler(raw []byte) error {
	var req *stripe.Sub
	err := json.Unmarshal(raw, &req)
	if err != nil {
		return err
	}

	eventName := fmt.Sprintf("trial of %s plan subscription will end", req.Plan.ID)

	return sendEventForCustomer(req.Customer.ID, eventName, nil)
}

func invoiceCreatedHandler(raw []byte) error {
	var invoice *stripe.Invoice
	err := json.Unmarshal(raw, &invoice)
	if err != nil {
		return err
	}

	return nil
}

func invoicePaymentFailedHandler(raw []byte) error {
	var invoice *stripe.Invoice
	err := json.Unmarshal(raw, &invoice)
	if err != nil {
		return err
	}

	return handleInvoiceStateChange(invoice)
}

func invoicePaymentSucceededHandler(raw []byte) error {
	var invoice *stripe.Invoice
	err := json.Unmarshal(raw, &invoice)
	if err != nil {
		return err
	}

	return handleInvoiceStateChange(invoice)
}

func handleInvoiceStateChange(invoice *stripe.Invoice) error {
	cus, err := customer.Get(invoice.Customer.ID, nil)
	if err != nil {
		return err
	}

	if cus.Subs.Count != 1 {
		// TODO CRITICAL
		return errors.New("customer should only have one subscription")
	}

	status := cus.Subs.Values[0].Status

	group, err := modelhelper.GetGroup(cus.Meta["groupName"])
	if err != nil {
		return err
	}

	if err := modelhelper.UpdateGroupPartial(
		modelhelper.Selector{"_id": group.Id},
		modelhelper.Selector{
			"$set": modelhelper.Selector{
				"payment.subscription.status": status,
			},
		},
	); err != nil {
		return err
	}

	eventName := fmt.Sprintf("invoice status changed to %s", status)
	return sendEventForCustomer(invoice.Customer.ID, eventName, nil)
}

func sendEventForCustomer(customerID string, eventName string, options map[string]interface{}) error {
	cus, err := customer.Get(customerID, nil)
	if err != nil {
		return err
	}

	if options == nil {
		options = make(map[string]interface{})
	}

	for key, val := range cus.Meta {
		options[key] = val
	}

	mail := &emailsender.Mail{
		To:      cus.Email,
		Subject: eventName,
		Properties: &emailsender.Properties{
			Username: cus.Meta["username"],
			Options:  options,
		},
	}

	return mailSender(mail)
}
