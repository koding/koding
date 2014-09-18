package stripe

func Unsubscribe(accId, planTitle, interval string) error {
	customer, err := FindCustomerByOldId(accId)
	if err != nil {
		return err
	}

	if customer == nil {
		return ErrCustomerNotFound
	}

	plan, err := FindPlanByTitleAndInterval(planTitle, interval)
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
		return ErrCustomerNotSubscribedToAnyPlans
	}

	if IsOverSubscribed(subscriptions) {
		return ErrCustomerHasTooManySubscriptions
	}

	var currentSubscription = subscriptions[0]

	if !IsSubscribedToPlan(currentSubscription, plan) {
		return ErrCustomerNotSubscribedToThatPlan
	}

	err = CancelSubscription(customer, currentSubscription)
	if err != nil {
		return err
	}

	err = RemoveCreditCard(customer)
	if err != nil {
		return err
	}

	return nil
}
