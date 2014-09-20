package stripe

import (
	"socialapi/models/paymentmodel"

	stripe "github.com/stripe/stripe-go"
	stripeSub "github.com/stripe/stripe-go/sub"
)

func Subscribe(token, accId, email, planTitle, planInterval string) error {
	plan, err := FindPlanByTitleAndInterval(planTitle, planInterval)
	if err != nil {
		return err
	}

	customer, err := FindCustomerByOldId(accId)
	if err != nil && err != ErrCustomerNotFound {
		return err
	}

	if customer == nil {
		if IsEmpty(token) {
			return ErrTokenIsEmpty
		}

		customer, err = CreateCustomer(token, accId, email)
		if err != nil {
			return err
		}
	}

	subscriptions, err := FindCustomerActiveSubscriptions(customer)
	if err != nil {
		return err
	}

	if IsNoSubscriptions(subscriptions) {
		_, err = CreateSubscription(customer, plan)
		return err
	}

	if IsOverSubscribed(subscriptions) {
		return ErrCustomerHasTooManySubscriptions
	}

	var currentSubscription = subscriptions[0]

	if IsSubscribedToPlan(currentSubscription, plan) {
		return ErrCustomerAlreadySubscribedToPlan
	}

	err = UpdateSubscriptionForCustomer(customer, subscriptions, plan)
	if err != nil {
		return err
	}

	if IsFreePlan(plan) {
		err := CancelSubscription(customer, &currentSubscription)
		if err != nil {
			return err
		}

		err = RemoveCreditCard(customer)
		if err != nil {
			return err
		}
	}

	return nil
}

func UpdateSubscriptionForCustomer(customer *paymentmodel.Customer, subscriptions []paymentmodel.Subscription, plan *paymentmodel.Plan) error {
	subParams := &stripe.SubParams{
		Customer: customer.ProviderCustomerId,
		Plan:     plan.ProviderPlanId,
	}

	if IsNoSubscriptions(subscriptions) {
		return ErrCustomerNotSubscribedToAnyPlans
	}

	currentSubscription := subscriptions[0]
	currentSubscriptionId := currentSubscription.ProviderSubscriptionId

	_, err := stripeSub.Update(currentSubscriptionId, subParams)
	if err != nil {
		return err
	}

	err = currentSubscription.UpdatePlan(plan.Id, plan.AmountInCents)
	if err != nil {
		return err
	}

	return err
}
