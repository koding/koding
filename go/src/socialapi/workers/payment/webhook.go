package payment

import (
	"encoding/json"
	"errors"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"socialapi/workers/api/realtimehelper"
	"socialapi/workers/email/emailsender"
	"strings"
	"time"

	"gopkg.in/mgo.v2"

	"github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/customer"
	stripeinvoice "github.com/stripe/stripe-go/invoice"
)

const (
	EventNameJoinedNewPricingTier = "joined new pricing tier"
)

var mailSender = emailsender.Send

// StripeHandler is the type of handlers for stripe webhook operations
type StripeHandler func([]byte) error

var stripeActions = map[string]StripeHandler{
	"charge.succeeded": chargeSucceededHandler,
	"charge.failed":    chargeFailedHandler,

	"customer.subscription.created":        customerSubscriptionCreatedHandler,
	"customer.subscription.deleted":        customerSubscriptionDeletedHandler,
	"customer.subscription.updated":        customerSubscriptionUpdatedHandler,
	"customer.subscription.trial_will_end": customerSubscriptionTrialWillEndHandler,
	"customer.source.created":              customerSourceCreatedHandler,
	"customer.source.deleted":              customerSourceDeletedHandler,

	"invoice.created":           invoiceCreatedHandler,
	"invoice.payment_failed":    invoicePaymentHandler,
	"invoice.payment_succeeded": invoicePaymentHandler,
}

// GetHandler returns the registered handler for stripe webhooks if registered
func GetHandler(name string) (StripeHandler, error) {
	action, ok := stripeActions[name]
	if !ok {
		return nil, errors.New("handler not found")
	}

	return action, nil
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

var oneDayTrialDur int64 = 24 * 60 * 60
var sevenDayTrialDur int64 = 7 * oneDayTrialDur
var thirtyDayTrialDur int64 = 30 * oneDayTrialDur

func customerSubscriptionCreatedHandler(raw []byte) error {
	var req *stripe.Sub
	err := json.Unmarshal(raw, &req)
	if err != nil {
		return err
	}

	eventName := fmt.Sprintf("subscribed to %s plan", req.Plan.ID)
	if err := sendEventForCustomer(req.Customer.ID, eventName, nil); err != nil {
		return err
	}

	if req.Status != "trialing" {
		return nil
	}

	durSec := req.TrialEnd - req.TrialStart
	durStr := ""
	switch durSec {
	case sevenDayTrialDur:
		durStr = "seven days"
	case thirtyDayTrialDur:
		durStr = "thirty days"
	default:
		durStr = time.Duration(durSec).String()
	}

	eventName = fmt.Sprintf("%s trial started", durStr)
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

	if err := sendEventForCustomer(req.Customer.ID, "three days left in trial", nil); err != nil {
		return err
	}

	eventName := fmt.Sprintf("trial of %s plan subscription will end", req.Plan.ID)

	return sendEventForCustomer(req.Customer.ID, eventName, nil)
}

func customerSourceCreatedHandler(raw []byte) error {
	var req *stripe.Card
	err := json.Unmarshal(raw, &req)
	if err != nil {
		return err
	}

	const eventName = "entered credit card"

	return sendEventForCustomer(req.Customer.ID, eventName, nil)
}

func customerSourceDeletedHandler(raw []byte) error {
	var req *stripe.Card
	err := json.Unmarshal(raw, &req)
	if err != nil {
		return err
	}

	const eventName = "credit card removed"

	return sendEventForCustomer(req.Customer.ID, eventName, nil)
}

func invoiceCreatedHandler(raw []byte) error {
	var invoice *stripe.Invoice
	err := json.Unmarshal(raw, &invoice)
	if err != nil {
		return err
	}

	// we cant do anything to the closed invoices.
	if invoice.Closed {
		return nil
	}

	if invoice.Paid {
		return nil
	}

	cus, err := customer.Get(invoice.Customer.ID, nil)
	if err != nil {
		return err
	}

	group, err := modelhelper.GetGroup(cus.Meta["groupName"])
	// we might get events from other environments where we might not have the
	// group in this env.
	if err == mgo.ErrNotFound {
		return nil
	}

	if err != nil {
		return err
	}

	// if customer id and subscription id is not set, we dont have the
	// appropriate data in our system, dont bother with the rest
	if group.Payment.Customer.ID == "" {
		return nil
	}

	if group.Payment.Subscription.ID == "" {
		return nil
	}

	info, err := GetInfoForGroup(group)
	if err != nil {
		return err
	}

	if strings.HasPrefix(info.Subscription.Plan.ID, customPlanPrefix) {
		return (&models.PresenceDaily{}).ProcessByGroupName(group.Slug)
	}

	// if the amount that stripe will withdraw and what we want is same, so we
	// are done. Subtotal -> Total of all subscriptions, invoice items, and
	// prorations on the invoice before any discount is applied
	if invoice.Subtotal == int64(info.Due) {
		// clean up waiting deleted users
		return (&models.PresenceDaily{}).ProcessByGroupName(group.Slug)
	}

	// if this in the tests, just skip cancellation of the invoice, because
	// there is no way to create and invoice and have it open for a while.
	if invoice.ID != "in_00000000000000" {
		// first close the invoice
		_, err = stripeinvoice.Update(invoice.ID, &stripe.InvoiceParams{Closed: true})
		if err != nil {
			return err
		}
	}

	planID := GetPlanID(info.User.Total)

	prevSub, err := DeleteSubscriptionForGroup(cus.Meta["groupName"])
	if err != nil {
		return err
	}

	params := &stripe.SubParams{
		Customer: group.Payment.Customer.ID,
		Plan:     planID,
		Quantity: uint64(info.User.Total),
	}

	sub, err := CreateSubscriptionForGroup(cus.Meta["groupName"], params)
	if err != nil {
		return err
	}

	if err := (&models.PresenceDaily{}).ProcessByGroupName(group.Slug); err != nil {
		return err
	}

	opts := map[string]interface{}{
		"oldPlanID": prevSub.Plan.ID,
		"newPlanID": sub.Plan.ID,
	}
	return sendEventForCustomer(cus.ID, EventNameJoinedNewPricingTier, opts)
}

func invoicePaymentHandler(raw []byte) error {
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
	// we might get events from other environments where we might not have the
	// group in this env.
	if err == mgo.ErrNotFound {
		return nil
	}

	if err != nil {
		return err
	}

	if group.Payment.Subscription.Status == string(status) {
		return nil
	}

	// send instance notification to group
	go realtimehelper.NotifyGroup(
		group.Slug,
		"payment_status_changed",
		map[string]string{
			"oldStatus": group.Payment.Subscription.Status,
			"newStatus": string(status),
		},
	)

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

	eventName := fmt.Sprintf("subscription status %s", status)
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
