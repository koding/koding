package stripe

import "socialapi/workers/payment/paymenterrors"

func Subscribe(token, accId, email, planTitle, planInterval string) error {
	plan, err := FindPlanByTitleAndInterval(planTitle, planInterval)
	if err != nil {
		return err
	}

	customer, err := FindCustomerByOldId(accId)
	if err != nil && err != paymenterrors.ErrCustomerNotFound {
		return err
	}

	if customer == nil {
		customer, err = CreateCustomer(token, accId, email)
		if err != nil {
			return err
		}
	}

	err = UpdateCreditCardIfEmpty(accId, token)
	if err != nil {
		return err
	}

	subscriptions, err := FindCustomerActiveSubscriptions(customer)
	if err != nil {
		return err
	}

	if IsNoSubscriptions(subscriptions) {
		_, err := CreateSubscription(customer, plan)

		if err != nil {
			RemoveCreditCard(customer) // outer error is more important
			return err
		}

		return nil
	}

	if IsOverSubscribed(subscriptions) {
		return paymenterrors.ErrCustomerHasTooManySubscriptions
	}

	var currentSubscription = subscriptions[0]

	if IsSubscribedToPlan(currentSubscription, plan) {
		return paymenterrors.ErrCustomerAlreadySubscribedToPlan
	}

	if !IsFreePlan(plan) {
		err := UpdateSubscriptionForCustomer(customer, subscriptions, plan)

		if err != nil {
			RemoveCreditCard(customer) // outer error is more important
			return err
		}

		return nil
	}

	err = CancelSubscriptionAndRemoveCC(customer, &currentSubscription)
	if err != nil {
		return err
	}

	return nil
}
