package paypal

import (
	"errors"
	"fmt"
	"socialapi/config"
	"socialapi/workers/payment/paymentmodels"
	"strings"

	"github.com/koding/logging"
	"github.com/koding/paypal"
)

const (
	ProviderName = "paypal"
	Month        = "Month"
	Year         = "Year"
)

var (
	Log                  = logging.NewLogger("payment")
	client               *paypal.PayPalClient
	returnURL, cancelURL string
)

func InitializeClientKey(creds config.Paypal) {
	returnURL = creds.ReturnUrl
	cancelURL = creds.CancelUrl

	client = paypal.NewDefaultClient(
		creds.Username, creds.Password, creds.Signature, creds.IsSandbox,
	)
}

func Client() (*paypal.PayPalClient, error) {
	if err := isClientInitialized(); err != nil {
		return nil, err
	}

	return client, nil
}

func isClientInitialized() error {
	if client == nil {
		return errors.New("paypal client unitialized")
	}

	if returnURL == "" {
		return errors.New("return url is empty")
	}

	if cancelURL == "" {
		return errors.New("cancel url is empty")
	}

	return nil
}

func amount(cents uint64) float64 {
	return float64(cents)
}

func normalizeAmount(amount uint64) string {
	return fmt.Sprintf("%G", float64(amount)/100)
}

func handlePaypalErr(response *paypal.PayPalResponse, err error) error {
	if err != nil {
		return err
	}

	if response.Ack != "Success" {
		Log.Error("%s", response)
		return errors.New("paypal request failed")
	}

	return nil
}

func getInterval(interval string) string {
	switch interval {
	case "month":
		return Month
	case "year":
		return Year
	default:
		return Month
	}
}

func goodName(plan *paymentmodels.Plan) string {
	return fmt.Sprintf("%s %s",
		strings.Title(plan.Title), strings.Title(plan.Interval),
	)
}
