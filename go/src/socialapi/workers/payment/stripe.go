package payment

import (
	"errors"
	"fmt"
)

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
