package paypal

import (
	"errors"
	"socialapi/workers/payment/paymentmodels"
)

func FindPlanFromToken(token, cType string) (*paymentmodels.Plan, error) {
	client, err := Client()
	if err != nil {
		return nil, err
	}

	resp, err := client.GetExpressCheckoutDetails(token)
	err = handlePaypalErr(resp, err)
	if err != nil {
		return nil, err
	}

	planInfo := resp.Values.Get("L_PAYMENTREQUEST_0_NAME0")
	if planInfo == "" {
		return nil, errors.New("no plan title or interval in paypal token")
	}

	planTitle, planInterval := parsePlanInfo(planInfo)

	plan := paymentmodels.NewPlan()
	if err = plan.ByTitleAndInterval(planTitle, planInterval, cType); err != nil {
		return nil, err
	}

	return plan, nil
}
