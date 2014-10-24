package stripe

import (
	"socialapi/workers/payment/paymentmodels"

	stripe "github.com/stripe/stripe-go"
)

func IsEmpty(str string) bool {
	return str == ""
}

func IsFreePlan(plan *paymentmodels.Plan) bool {
	return plan.Title == "free"
}

func IsOverSubscribed(subscriptions []paymentmodels.Subscription) bool {
	return len(subscriptions) > 1
}

func IsNoSubscriptions(subscriptions []paymentmodels.Subscription) bool {
	return len(subscriptions) == 0
}

func IsSubscribedToPlan(subscription paymentmodels.Subscription, plan *paymentmodels.Plan) bool {
	if subscription.PlanId == 0 || plan.Id == 0 {
		Log.Error("unitialized subscription: %v and plan: %v id comparison", subscription, plan)
		return false
	}

	return subscription.PlanId == plan.Id
}

func IsNoCreditCards(cardList *stripe.CardList) bool {
	return cardList.Count == 0
}

func IsTooManyCreditCards(cardList *stripe.CardList) bool {
	return cardList.Count > 1
}

func IsCreditCardEmpty(ccResp *CreditCardResponse) bool {
	return ccResp.LastFour == ""
}

func IsDowngrade(oldPlan, newPlan *paymentmodels.Plan) bool {
	oldPlanValue := GetPlanValue(
		oldPlan.Title, oldPlan.Interval,
	)

	newPlanValue := GetPlanValue(newPlan.Title, newPlan.Interval)

	return newPlanValue < oldPlanValue
}

func IsLineCountAllowed(count int) bool {
	if count == 0 {
		Log.Error("Received 0 line items for invoice.created webhook.")
		return false
	}

	if count > 1 {
		Log.Notice("Received more than 1 line item for invoice.created webhook.")
	}

	return true
}
