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
	var active = 0

	for _, subscription := range subscriptions {
		if subscription.State == paymentmodels.SubscriptionStateActive {
			active += 1
		}
	}

	return active > 1
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
	return cardList == nil || cardList.Count == 0
}

func IsTooManyCreditCards(cardList *stripe.CardList) bool {
	return cardList.Count > 1
}

func IsCreditCardEmpty(ccResp *CreditCardResponse) bool {
	return ccResp.LastFour == ""
}

func IsLineCountAllowed(count int) bool {
	if count == 0 {
		return false
	}

	return true
}
