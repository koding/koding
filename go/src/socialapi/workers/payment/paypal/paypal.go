package paypal

import (
	"fmt"
	"socialapi/workers/payment/paymentmodels"
	"strconv"

	"github.com/koding/logging"
	"github.com/koding/paypal"
)

const (
	CurrencyCode = "USD"
	ProviderName = "paypal"
)

var (
	// TODO: get from config
	username  = "senthil+1_api1.koding.com"
	password  = "JFH6LXW97QN588RC"
	signature = "AFcWxV21C7fd0v3bYYYRCpSSRl31AjnvzeXiWRC89GOtfhnGMSsO563z"
	returnURL = "http://lvh.me:8090/-/payments/paypal/return"
	cancelURL = "http://lvh.me:8090/-/payments/paypal/cancel"
	isSandbox = true
	client    = paypal.NewDefaultClient(username, password, signature, isSandbox)
	Log       = logging.NewLogger("payment")
)

func amount(cents uint64) float64 {
	return float64(cents)
}

func normalizeAmount(amount uint64) string {
	return strconv.Itoa(int(amount))
}

func handlePaypalErr(response *paypal.PayPalResponse, err error) error {
	if err != nil {
		return err
	}

	// if response.Ack != "SUCCESS" || response.Ack != "Success {
	//   return errors.New("paypal request failed")
	// }

	return nil
}

func getInterval(interval string) string {
	switch interval {
	case "monthly":
		return "Month"
	case "yearly":
		return "Year"
	default:
		return "Month"
	}
}

func goodName(plan *paymentmodels.Plan) string {
	return fmt.Sprintf("%s-%s", plan.Title, plan.Interval)
}
