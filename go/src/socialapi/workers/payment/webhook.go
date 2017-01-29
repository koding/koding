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

	stripe "github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/customer"
	stripeinvoice "github.com/stripe/stripe-go/invoice"
	mgo "gopkg.in/mgo.v2"
)

const (
	eventNameJoinedNewPricingTier = "joined new pricing tier"
)

var mailSender = emailsender.Send

// StripeHandler is the type of handlers for stripe webhook operations
type StripeHandler func([]byte) error

var stripeActions = map[string]StripeHandler{
	"customer.subscription.created":        customerSubscriptionCreatedHandler,
	"customer.subscription.deleted":        customerSubscriptionDeletedHandler,
	"customer.subscription.updated":        customerSubscriptionUpdatedHandler,
	"customer.subscription.trial_will_end": customerSubscriptionTrialWillEndHandler,
	"customer.source.created":              customerSourceCreatedHandler,
	"customer.source.deleted":              customerSourceDeletedHandler,

	"invoice.created":           invoiceCreatedHandler,
	"invoice.payment_failed":    invoicePaymentFailedHandler,
	"invoice.payment_succeeded": invoicePaymentSucceededHandler,
}

// GetHandler returns the registered handler for stripe webhooks if registered
func GetHandler(name string) (StripeHandler, error) {
	action, ok := stripeActions[name]
	if !ok {
		return nil, errors.New("handler not found")
	}

	return action, nil
}

func getAmountOpts(currency string, amount int64) map[string]interface{} {
	formatted := formatCurrency(currency, amount)
	return map[string]interface{}{"amount": formatted}
}

func formatCurrency(currencyStr string, amount int64) string {
	switch currencyStr {
	case "USD", "usd":
		currencyStr = "$"
	default:
		return ""
	}

	return fmt.Sprintf("%s%v", currencyStr, amount/100)
}

var oneDayTrialDur int64 = 24 * 60 * 60
var sevenDayTrialDur = 7 * oneDayTrialDur

func customerSubscriptionCreatedHandler(raw []byte) error {
	var req stripe.Sub
	err := json.Unmarshal(raw, &req)
	if err != nil {
		return err
	}

	eventName := fmt.Sprintf("subscribed to %s plan", req.Plan.ID)
	if err := sendEventForCustomer(req.Customer.ID, eventName, nil); err != nil {
		return err
	}

	if err := syncGroupWithCustomerID(req.Customer.ID); err != nil {
		return err
	}

	if req.Status != "trialing" {
		return nil
	}

	durSec := req.TrialEnd - req.TrialStart
	durStr := ""
	if durSec > 0 {
		durStr = "seven days"
	}
	if durSec > sevenDayTrialDur {
		durStr = "thirty days"
	}

	eventName = fmt.Sprintf("%s trial started", durStr)
	return sendEventForCustomer(req.Customer.ID, eventName, nil)
}

func customerSubscriptionDeletedHandler(raw []byte) error {
	var req stripe.Sub
	err := json.Unmarshal(raw, &req)
	if err != nil {
		return err
	}

	if err := syncGroupWithCustomerID(req.Customer.ID); err != nil {
		return err
	}

	eventName := fmt.Sprintf("unsubscribed from %s plan", req.Plan.ID)

	return sendEventForCustomer(req.Customer.ID, eventName, nil)
}

func customerSubscriptionUpdatedHandler(raw []byte) error {
	var req stripe.Sub
	err := json.Unmarshal(raw, &req)
	if err != nil {
		return err
	}

	// on sub update, update info from db.
	if err := syncGroupWithCustomerID(req.Customer.ID); err != nil {
		return err
	}

	eventName := fmt.Sprintf("subscription of %s plan updated", req.Plan.ID)

	return sendEventForCustomer(req.Customer.ID, eventName, nil)
}

func customerSubscriptionTrialWillEndHandler(raw []byte) error {
	var req stripe.Sub
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
	var req stripe.Card
	err := json.Unmarshal(raw, &req)
	if err != nil {
		return err
	}

	if err := syncGroupWithCustomerID(req.Customer.ID); err != nil {
		return err
	}

	const eventName = "entered credit card"

	return sendEventForCustomer(req.Customer.ID, eventName, nil)
}

func customerSourceDeletedHandler(raw []byte) error {
	var req stripe.Card
	err := json.Unmarshal(raw, &req)
	if err != nil {
		return err
	}

	if err := syncGroupWithCustomerID(req.Customer.ID); err != nil {
		return err
	}

	const eventName = "credit card removed"

	return sendEventForCustomer(req.Customer.ID, eventName, nil)
}

func invoiceCreatedHandler(raw []byte) error {
	var invoice stripe.Invoice
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
	if err == mgo.ErrNotFound {
		return nil
	}

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
	// there is no way to create an invoice and have it open for a while.
	if invoice.ID != "in_00000000000000" {
		// first close the invoice
		_, err = stripeinvoice.Update(invoice.ID, &stripe.InvoiceParams{Closed: true})
		if err != nil {
			return err
		}
	}

	return switchToNewSub(info)
}

func switchToNewSub(info *Usage) error {
	groupName := info.Customer.Meta["groupName"]

	planID := GetPlanID(info.User.Total)

	prevSub, err := DeleteSubscriptionForGroup(groupName)
	if err != nil {
		return err
	}

	params := &stripe.SubParams{
		Customer: info.Customer.ID,
		Plan:     planID,
		Quantity: uint64(info.User.Total),
	}
	sub, err := EnsureSubscriptionForGroup(groupName, params)
	if err != nil {
		return err
	}

	if err := (&models.PresenceDaily{}).ProcessByGroupName(groupName); err != nil {
		return err
	}

	opts := map[string]interface{}{
		"oldPlanID": prevSub.Plan.ID,
		"newPlanID": sub.Plan.ID,
	}
	return sendEventForCustomer(info.Customer.ID, eventNameJoinedNewPricingTier, opts)
}

func invoicePaymentFailedHandler(raw []byte) error {
	return invoicePaymentHandler(raw, "payment failed")
}

func invoicePaymentSucceededHandler(raw []byte) error {
	return invoicePaymentHandler(raw, "payment succeeded")
}

func invoicePaymentHandler(raw []byte, eventName string) error {
	var invoice stripe.Invoice
	err := json.Unmarshal(raw, &invoice)
	if err != nil {
		return err
	}

	go sendInvoiceEvent(&invoice, eventName)

	return handleInvoiceStateChange(&invoice)
}

func handleInvoiceStateChange(invoice *stripe.Invoice) error {
	cus, err := customer.Get(invoice.Customer.ID, nil)
	if err != nil {
		return err
	}

	if err := syncGroupWithCustomerID(invoice.Customer.ID); err != nil {
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

	status := group.Payment.Subscription.Status

	// if sub is in cancelled state within 2 months send an event
	if stripe.SubStatus(status) == SubStatusCanceled {
		// if group has been created in last 2 months (1 month trial + 1 month free)
		totalTrialTime := time.Now().UTC().Add(-time.Hour * 24 * 60)
		if group.Id.Time().After(totalTrialTime) {
			eventName := "trial ended without payment"
			sendEventForCustomer(invoice.Customer.ID, eventName, nil)
		}
	}

	// send instance notification to group
	go realtimehelper.NotifyGroup(
		group.Slug,
		"payment_status_changed",
		map[string]string{
			"oldStatus": string(group.Payment.Subscription.Status),
			"newStatus": string(status),
		},
	)

	eventName := fmt.Sprintf("subscription status %s", status)
	return sendEventForCustomer(invoice.Customer.ID, eventName, nil)
}

func sendInvoiceEvent(invoice *stripe.Invoice, eventName string) error {
	opts := getAmountOpts(string(invoice.Currency), invoice.Amount)
	return sendEventForCustomer(invoice.Customer.ID, eventName, opts)
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

	admins, err := modelhelper.FetchAdminAccounts(cus.Meta["groupName"])
	if err == mgo.ErrNotFound {
		return nil
	}

	if err != nil {
		return err
	}

	for _, admin := range admins {
		user, err := modelhelper.GetUser(admin.Profile.Nickname)
		if err != nil {
			return err
		}

		mail := &emailsender.Mail{
			To:      user.Email,
			Subject: eventName,
			Properties: &emailsender.Properties{
				Username: user.Name,
				Options:  options,
			},
		}

		if err := mailSender(mail); err != nil {
			return err
		}
	}

	return nil
}
