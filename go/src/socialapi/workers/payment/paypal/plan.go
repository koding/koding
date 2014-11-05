package paypal

import (
	"errors"
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"
)

func FindPlanFromToken(token string) (*paymentmodels.Plan, error) {
	resp, err := client.GetExpressCheckoutDetails(token)
	err = handlePaypalErr(resp, err)
	if err != nil {
		return nil, err
	}

	planTitleAndInterval := resp.Values.Get("L_PAYMENTREQUEST_0_NAME0")
	if planTitleAndInterval == "" {
		return nil, errors.New("no plan title or interval in paypal token")
	}

	planTitle, planInterval := parsePlanInfo(planTitleAndInterval)
	plan := paymentmodels.NewPlan()

	err = plan.ByTitleAndInterval(planTitle, planInterval)
	if err != nil {
		if paymenterrors.IsPlanNotFoundErr(err) {
			return nil, paymenterrors.ErrPlanNotFound
		}

		return nil, err
	}

	return plan, nil
}
