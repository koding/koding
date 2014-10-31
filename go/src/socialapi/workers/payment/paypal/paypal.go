package paypal

import (
	"errors"
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"

	"github.com/koding/paypal"
)

const CurrencyCode = "USD"

var (
	// TODO: get from config
	username  = "senthil+1_api1.koding.com"
	password  = "JFH6LXW97QN588RC"
	signature = "AFcWxV21C7fd0v3bYYYRCpSSRl31AjnvzeXiWRC89GOtfhnGMSsO563z"
	returnURL = "http://localhost:4567"
	cancelURL = "http://localhost:4567"
	isSandbox = true
	client    = paypal.NewDefaultClient(username, password, signature, isSandbox)
)

func GetToken(planTitle, planInterval string) (string, error) {
	plan, err := FindPlanByTitleAndInterval(planTitle, planInterval)
	if err != nil {
		return "", err
	}

	item := paypal.NewDigitalGood(plan.Title, amount(plan.AmountInCents))

	args := paypal.NewExpressCheckoutSingleArgs()
	args.ReturnURL = returnURL
	args.CancelURL = cancelURL
	// args.BuyerId   = "jones"
	args.Item = item

	response, err := client.SetExpressCheckoutSingle(args)
	if err != nil {
		return "", err
	}

	token := response.Values.Get("TOKEN")
	if token == "" {
		return "", errors.New("token is empty")
	}

	return token, nil
}

// TODO: move to common location
func FindPlanByTitleAndInterval(title, interval string) (*paymentmodels.Plan, error) {
	plan := paymentmodels.NewPlan()

	err := plan.ByTitleAndInterval(title, interval)
	if err != nil {
		if paymenterrors.IsPlanNotFoundErr(err) {
			return nil, paymenterrors.ErrPlanNotFound
		}

		return nil, err
	}

	return plan, nil
}

func amount(cents uint64) float64 {
	return float64(cents)
}
