package paypal

import (
	"errors"
	"fmt"

	"github.com/koding/paypal"
)

func GetToken(planTitle, planInterval string) (string, error) {
	plan, err := FindPlanByTitleAndInterval(planTitle, planInterval)
	if err != nil {
		return "", err
	}

	digitalGoodName := fmt.Sprintf("%s-%s", plan.Title, plan.Interval)
	item := paypal.NewDigitalGood(digitalGoodName, amount(plan.AmountInCents))

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
