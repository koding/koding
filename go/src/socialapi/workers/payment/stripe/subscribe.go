package stripe

import "socialapi/models/paymentmodel"

func Subscribe(token, accId, email, planTitle string) error {
	customer, err := FindCustomerByOldId(accId)
	if err != nil {
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

	plan, err := FindPlanByTitle(planTitle)
	if err != nil {
		return err
	}

	if plan == nil {
		return ErrPlanNotFound
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

	err = UpdateSubscriptionForCustomer(customer, plan)
	if err != nil {
		return err
	}

	if IsFreePlan(plan) {
		err = RemoveCreditCard(customer)
		return err
	}

	return nil
}

func UpdateSubscriptionForCustomer(customer *paymentmodel.Customer, plan *paymentmodel.Plan) error {
	return nil
}

func RemoveCreditCard(customer *paymentmodel.Customer) error {
	return nil
}
