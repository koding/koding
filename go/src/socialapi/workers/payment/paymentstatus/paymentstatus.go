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
	NewSub                  Status = iota
	ExpiredSub              Status = iota
	ExistingUserHasNoSub    Status = iota
	AlreadySubscribedToPlan Status = iota
	DowngradeToFreePlan     Status = iota
	DowngradeToNonFreePlan  Status = iota
	UpgradeFromExistingSub  Status = iota
)

func Check(customer *paymentmodels.Customer, err error, plan *paymentmodels.Plan) (Status, error) {
	if IsNewSubscription(customer, err) {
		return NewSub, nil
	}

	if IsDowngradeToFreePlan(plan) {
		return DowngradeToFreePlan, nil
	}

	if sub, err := IsSubscribedToNotActiveSub(customer); err == nil && sub {
		return ExpiredSub, nil
	}

	currentSubscription, err := customer.FindActiveSubscription()
	if err == paymenterrors.ErrCustomerNotSubscribedToAnyPlans {
		return ExistingUserHasNoSub, nil
	}

	if err != nil {
		return Error, err
	}

	oldPlan := paymentmodels.NewPlan()
	if err := oldPlan.ById(currentSubscription.PlanId); err != nil {
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

// IsSubscribedToNotActiveSub returns if user has an active subscription. If an
// user has multiple subscriptions, active subscription takes precedence.
func IsSubscribedToNotActiveSub(customer *paymentmodels.Customer) (bool, error) {
	subscriptions, err := customer.FindSubscriptions()
	if err != nil && err != paymenterrors.ErrCustomerNotSubscribedToAnyPlans {
		return false, err
	}

	if len(subscriptions) == 0 || err == paymenterrors.ErrCustomerNotSubscribedToAnyPlans {
		return false, nil
	}

	var states = map[string]struct{}{}
	for _, sub := range subscriptions {
		states[sub.State] = struct{}{}
	}

	if _, ok := states[paymentmodels.SubscriptionStateActive]; ok {
		return false, nil
	}

	return true, nil
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
