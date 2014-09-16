package stripe

import "socialapi/models/paymentmodel"

func Exists(item interface{}) bool {
	return item != nil
}

func IsEmpty(str string) bool {
	return str == ""
}

func IsFreePlan(plan *paymentmodel.Plan) bool {
	return plan.AmountInCents == 0
}

func IsOverSubscribed(subscriptions []paymentmodel.Subscription) bool {
	return len(subscriptions) > 1
}

func IsNoSubscriptions(subscriptions []paymentmodel.Subscription) bool {
	return len(subscriptions) == 0
}

func IsSubscribedToPlan(subscription paymentmodel.Subscription, plan *paymentmodel.Plan) bool {
	return subscription.PlanId == plan.Id
}
