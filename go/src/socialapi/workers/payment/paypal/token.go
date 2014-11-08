package paypal

import (
	"errors"
	"socialapi/workers/payment/stripe"

	"github.com/koding/paypal"
)

func GetToken(planTitle, planInterval string) (string, error) {
	plan, err := stripe.FindPlanByTitleAndInterval(planTitle, planInterval)
	if err != nil {
		return "", err
	}

	item := paypal.NewDigitalGood(goodName(plan), amount(plan.AmountInCents))

	args := paypal.NewExpressCheckoutSingleArgs()
	args.ReturnURL = returnURL
	args.CancelURL = cancelURL
	// args.BuyerId   = "jones"
	args.Item = item

	client, err := Client()
	if err != nil {
		return "", err
	}

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
