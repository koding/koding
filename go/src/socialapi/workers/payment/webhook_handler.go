package payment

import (
	"encoding/json"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/email/emailsender"

	"github.com/kr/pretty"
	"github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/customer"
)

var mailSender = emailsender.Send

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
		fmt.Printf("customer should only have one sub %# v", pretty.Formatter(cus))
		// TODO CRITICAL
		return nil
	}

	status := cus.Subs.Values[0].Status

	// state :=
	groupName := cus.Meta["groupName"]

	group, err := modelhelper.GetGroup(groupName)
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
