package stripe

import (
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"
)

func Subscribe(token, accId, email, planTitle, planInterval string) error {
	plan, err := FindPlanByTitleAndInterval(planTitle, planInterval)
	if err != nil {
		return err
	}

	customer, err := paymentmodels.NewCustomer().ByOldId(accId)
	if err != nil && err != paymenterrors.ErrCustomerNotFound {
		return err
	}

	if err == paymenterrors.ErrCustomerNotFound {
		customer, err = CreateCustomer(token, accId, email)
		if err != nil {
			return err
		}
	}

	if IsFreePlan(plan) {
		subscriptions, err := customer.FindSubscriptions()
		if err != nil {
			return err
		}

		for _, sub := range subscriptions {
			err = CancelSubscriptionAndRemoveCC(customer, &sub)
			if err != nil {
				Log.Error(err.Error())
			}
		}

		return nil
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
			deleteCustomer(customer)
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

	err = UpdateSubscriptionForCustomer(customer, subscriptions, plan)

	if err != nil {
		removeCreditCardHelper(customer)
		return err
	}

	return nil
}

func deleteCustomer(customer *paymentmodels.Customer) {
	removeCreditCardHelper(customer)

	err := customer.Delete()
	if err != nil {
		Log.Error("Removing cc failed for customer: %v. %v", customer.Id, err)
	}
}

func removeCreditCardHelper(customer *paymentmodels.Customer) {
	ccErr := RemoveCreditCard(customer) // outer error is more important
	if ccErr != nil {
		Log.Error("Removing cc failed for customer: %v. %v", customer.Id, ccErr)
	}
}
