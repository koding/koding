package webhookmodels

import (
	"fmt"
	"strings"
	"time"
)

const PaypalTimeLayout = "15:04:05 Jan 02, 2006 MST"

// Paypal is so special it deverses it's own time format.
type PaypalOwnTime struct {
	time.Time
}

func (pt *PaypalOwnTime) UnmarshalJSON(b []byte) error {
	var err error

	pt.Time, err = time.Parse(PaypalTimeLayout, strings.Replace(fmt.Sprintf("%s", b), `"`, "", -1))

	return err
}

type PaypalGenericWebhook struct {
	TransactionType string        `json:"txn_type"`
	Status          string        `json:"payment_status"`
	PayerId         string        `json:"recurring_payment_id"`
	Plan            string        `json:"product_name"`
	Amount          string        `json:"amount"`
	Currency        string        `json:"currency_code"`
	NextPaymentDate PaypalOwnTime `json:"next_payment_date"`
	PaymentDate     PaypalOwnTime `json:"payment_date"`
}
