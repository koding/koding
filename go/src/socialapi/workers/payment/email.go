package payment

import (
	"errors"
	"fmt"

	"github.com/kr/pretty"
)

type Action int

const (
	SubscriptionCreated Action = iota
	SubscriptionChanged
	SubscriptionDeleted
	PaymentCreated
	PaymentRefunded
	PaymentFailed
)

var EmailSubjects = map[Action]string{
	SubscriptionCreated: "bought a subscription",
	SubscriptionDeleted: "canceled their subscription",
	SubscriptionChanged: "changed their subscription",
	PaymentCreated:      "received an invoice",
	PaymentRefunded:     "received a refuned",
	PaymentFailed:       "failed to pay",
}

var ErrEmailActionNotFound = errors.New("action not found")

func formatCurrency(currencyStr string, amount uint64) string {
	fmt.Printf("currencyStr %# v", pretty.Formatter(currencyStr))
	switch currencyStr {
	case "USD", "usd":
		currencyStr = "$"
	default:
		return ""
	}

	return fmt.Sprintf("%s%v", currencyStr, amount/100)
}
