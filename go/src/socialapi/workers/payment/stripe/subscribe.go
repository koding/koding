package stripe

import (
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"
	"socialapi/workers/payment/paymentstatus"

	stripeCustomer "github.com/stripe/stripe-go/customer"
)

func SubscribeForGroup(token, groupId, email, planTitle, planInterval string) error {
	return subscribe(token, email, planTitle, planInterval, groupId, paymentmodels.GroupCustomer)
}

func SubscribeForAccount(token, accId, email, planTitle, planInterval string) error {
	return subscribe(token, email, planTitle, planInterval, accId, paymentmodels.AccountCustomer)
}

func subscribe(token, email, planTitle, planInterval, id string, cType string) error {
	plan, err := FindPlanByTitleAndInterval(planTitle, planInterval)
	if err != nil {
		return err
	}

	customer, err := paymentmodels.NewCustomer().ByOldIdAndType(id, cType)
	if err != nil && err != paymenterrors.ErrCustomerNotFound {
		return err
	}

	var subscription *paymentmodels.Subscription
	if customer != nil {
		subscription, err = customer.FindActiveSubscription()
		if err != nil && err != paymenterrors.ErrCustomerNotSubscribedToAnyPlans {
			return err
		}
	}

	status, err := paymentstatus.Check(customer, err, plan)
	if err != nil {
		Log.Error("Subscribing to %s failed for user: %s", plan.Title, customer.Username)
		return err
	}

	switch status {
	case paymentstatus.NewSub, paymentstatus.ExpiredSub:
		err = handleNewSubscription(token, email, id, cType, plan)
	case paymentstatus.ExistingUserHasNoSub:
		err = handleUserNoSub(customer, token, plan)
	case paymentstatus.AlreadySubscribedToPlan:
		err = paymenterrors.ErrCustomerAlreadySubscribedToPlan
	case paymentstatus.DowngradeToFreePlan:
		err = handleCancel(customer)
	case paymentstatus.DowngradeToNonFreePlan:
		err = handleDowngrade(subscription, customer, plan)
	case paymentstatus.UpgradeFromExistingSub:
		err = handleUpgrade(subscription, customer, plan)
	default:
		Log.Error("User: %s fell into default case when subscribing: %s", customer.Username, plan.Title)
		// user should never come here
	}

	return err
}

func handleNewSubscription(token, email, id, cType string, plan *paymentmodels.Plan) error {
	var customer *paymentmodels.Customer

	switch cType {
	case paymentmodels.AccountCustomer:
		var err error
		if customer, err = CreateCustomer(token, id, email); err != nil {
			return err
		}
	case paymentmodels.GroupCustomer:
		var err error
		if customer, err = CreateCustomerForGroup(token, id, email); err != nil {
			return err
		}
	}

	if _, err := CreateSubscription(customer, plan); err != nil {
		deleteCustomer(customer)
		return err
	}

	return nil
}

func handleUserNoSub(customer *paymentmodels.Customer, token string, plan *paymentmodels.Plan) error {
	if token != "" {
		if err := UpdateCreditCard(customer.OldId, token); err != nil {
			return err
		}
	}

	_, err := CreateSubscription(customer, plan)
	return err
}

func handleCancel(customer *paymentmodels.Customer) error {
	subscriptions, err := customer.FindSubscriptions()
	if err != nil {
		return err
	}

	for _, sub := range subscriptions {
		if err = CancelSubscription(customer, &sub); err != nil {
			Log.Error(err.Error())
		}
	}

	removeCreditCardHelper(customer)

	return nil
}

func deleteCustomer(customer *paymentmodels.Customer) {
	removeCreditCardHelper(customer)

	if err := stripeCustomer.Del(customer.ProviderCustomerId); err != nil {
		Log.Error("Error deleting customer from Stripe: %v", err)
	}

	if err := customer.Delete(); err != nil {
		Log.Error("Removing cc failed for customer: %v. %v", customer.Id, err)
	}
}

func removeCreditCardHelper(customer *paymentmodels.Customer) {
	ccErr := RemoveCreditCard(customer) // outer error is more important
	if ccErr != nil {
		Log.Error("Removing cc failed for customer: %v. %v", customer.Id, ccErr)
	}
}
