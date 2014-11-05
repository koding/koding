package paypal

import (
	"errors"
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"
	"strings"
)

func Subscribe(token, accId string) error {
	resp, err := client.GetExpressCheckoutDetails(token)
	err = handlePaypalErr(resp, err)
	if err != nil {
		return err
	}

	planTitleAndInterval := resp.Values.Get("L_PAYMENTREQUEST_0_NAME0")
	if planTitleAndInterval == "" {
		return errors.New("no plan title or interval in paypal token")
	}

	planTitle, planInterval := parsePlanInfo(planTitleAndInterval)
	plan, err := FindPlanByTitleAndInterval(planTitle, planInterval)
	if err != nil {
		return err
	}

	_, err = FindCustomerByOldId(accId)
	if err != nil && err != paymenterrors.ErrCustomerNotFound {
		return err
	}

	if err == paymenterrors.ErrCustomerNotFound {
		err = handlNewSubscription(token, accId, plan)
		return err
	}

	return nil
}

func handlNewSubscription(token, accId string, plan *paymentmodels.Plan) error {
	customer, err := CreateCustomer(accId)
	if err != nil {
		return err
	}

	return CreateSubscription(token, plan, customer)
}

func parsePlanInfo(str string) (string, string) {
	split := strings.Split(str, "-")
	planTitle, planInterval := split[0], split[1]

	return planTitle, planInterval
}
