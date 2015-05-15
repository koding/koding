package webhookmodels

import (
	"fmt"
	"strings"
	"time"
)

const PaypalTimeLayout = "15:04:05 Jan 02, 2006 MST"

// Paypal is so special it deverses it's own time format.
type PaypalTime struct {
	time.Time
}

func (pt *PaypalTime) UnmarshalJSON(b []byte) error {
	str := strings.Replace(fmt.Sprintf("%s", b), `"`, "", -1)

	// paypal send `N/A` when time is nil
	if str == "" || str == "N/A" {
		return nil
	}

	var err error
	pt.Time, err = time.Parse(PaypalTimeLayout, str)

	return err
}

type PaypalGenericWebhook struct {
	TransactionType string     `json:"txn_type"`
	Status          string     `json:"payment_status"`
	PayerId         string     `json:"recurring_payment_id"`
	Plan            string     `json:"product_name"`
	Amount          string     `json:"amount"`
	Currency        string     `json:"currency_code"`
	NextPaymentDate PaypalTime `json:"next_payment_date"`
	PaymentDate     PaypalTime `json:"payment_date"`
}
