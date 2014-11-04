package paypal

import (
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"
)

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
