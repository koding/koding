package paypal

import (
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"
	"socialapi/workers/payment/stripe"
)

type status int

const (
	Default                 status = iota
	Error                   status = iota
	AlreadySubscribedToPlan status = iota
	NewSubscription         status = iota
	DowngradeToFreePlan     status = iota
	Downgrade               status = iota
	Upgrade                 status = iota
)

func checkStatus(customer *paymentmodels.Customer, err error, plan *paymentmodels.Plan) (status, error) {
	if IsNewSubscription(customer, err) {
		return NewSubscription, nil
	}

	currentSubscription, err := customer.FindActiveSubscription()
	if err != nil {
		return Error, err
	}

	oldPlan := paymentmodels.NewPlan()
	err = oldPlan.ById(currentSubscription.PlanId)
	if err != nil {
		return Error, err
	}

	if IsAlreadySubscribedToPlan(oldPlan, plan) {
		return AlreadySubscribedToPlan, nil
	}

	if IsDowngradeToFreePlan(plan) {
		return DowngradeToFreePlan, nil
	}

	if IsDowngrade(oldPlan, plan) {
		return Downgrade, nil
	}

	if IsUpgrade(oldPlan, plan) {
		return Upgrade, nil
	}

	return Default, nil
}

func IsNewSubscription(customer *paymentmodels.Customer, err error) bool {
	if customer == nil && err == paymenterrors.ErrCustomerNotFound {
		return true
	}

	return false
}

func IsAlreadySubscribedToPlan(oldPlan, plan *paymentmodels.Plan) bool {
	if oldPlan.Id == 0 || plan.Id == 0 {
		// LOG
		return false
	}

	return oldPlan.Id == plan.Id
}

func IsDowngradeToFreePlan(plan *paymentmodels.Plan) bool {
	return plan.Title == "free"
}

func IsDowngrade(oldPlan, plan *paymentmodels.Plan) bool {
	oldPlanValue := stripe.GetPlanValue(
		oldPlan.Title, oldPlan.Interval,
	)

	newPlanValue := stripe.GetPlanValue(plan.Title, plan.Interval)

	return newPlanValue < oldPlanValue
}

func IsUpgrade(oldPlan, plan *paymentmodels.Plan) bool {
	return !IsDowngrade(oldPlan, plan)
}
