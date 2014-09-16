package stripe

func Unsubscribe(accId, planTitle string) error {
	customer, err := FindCustomerByOldId(accId)
	if err != nil {
		return err
	}

	if Exists(customer) {
		return ErrCustomerNotFound
	}

	plan, err := FindPlanByTitle(planTitle)
	if err != nil {
		return err
	}

	if Exists(plan) {
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
