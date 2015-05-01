package paymentstatus

import (
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"
	"socialapi/workers/payment/paymentplan"
)

type Status int

const (
	Default                 Status = iota
	Error                   Status = iota
	NewSubscription         Status = iota
	ExistingUserHasNoSub    Status = iota
	AlreadySubscribedToPlan Status = iota
	DowngradeToFreePlan     Status = iota
	DowngradeToNonFreePlan  Status = iota
	UpgradeFromExistingSub  Status = iota
)

func Check(customer *paymentmodels.Customer, err error, plan *paymentmodels.Plan) (Status, error) {
	if IsNewSubscription(customer, err) {
		return NewSubscription, nil
	}

	if IsDowngradeToFreePlan(plan) {
		return DowngradeToFreePlan, nil
	}

	currentSubscription, err := customer.FindActiveSubscription()
	if err != nil && err != paymenterrors.ErrCustomerNotSubscribedToAnyPlans {
		return Error, err
	}

	if err == paymenterrors.ErrCustomerNotSubscribedToAnyPlans {
		return ExistingUserHasNoSub, nil
	}

	oldPlan := paymentmodels.NewPlan()
	err = oldPlan.ById(currentSubscription.PlanId)
	if err != nil {
		return Error, err
	}

	if IsAlreadySubscribedToPlan(oldPlan, plan) {
		return AlreadySubscribedToPlan, nil
	}

	if IsDowngradeToNonFreePlan(oldPlan, plan) {
		return DowngradeToNonFreePlan, nil
	}

	if IsUpgradeFromExistingSub(oldPlan, plan) {
		return UpgradeFromExistingSub, nil
	}

	return Default, nil
}

func IsNewSubscription(customer *paymentmodels.Customer, err error) bool {
	return customer == nil && err == paymenterrors.ErrCustomerNotFound
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

func IsDowngradeToNonFreePlan(oldPlan, plan *paymentmodels.Plan) bool {
	oldPlanValue := paymentplan.GetPlanValue(
		oldPlan.Title, oldPlan.Interval,
	)

	newPlanValue := paymentplan.GetPlanValue(plan.Title, plan.Interval)

	return newPlanValue < oldPlanValue
}

func IsUpgradeFromExistingSub(oldPlan, plan *paymentmodels.Plan) bool {
	return !IsDowngradeToNonFreePlan(oldPlan, plan)
}
