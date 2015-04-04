package stripe

import (
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"
	"socialapi/workers/payment/paymentstatus"

	stripeCustomer "github.com/stripe/stripe-go/customer"
)

func Subscribe(token, accId, email, planTitle, planInterval string) error {
	plan, err := FindPlanByTitleAndInterval(planTitle, planInterval)
	if err != nil {
		return err
	}

	return subscribe(token, accId, email, plan)
}

func subscribe(token, accId, email string, plan *paymentmodels.Plan) error {
	customer, err := paymentmodels.NewCustomer().ByOldId(accId)
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
	case paymentstatus.NewSubscription:
		err = handleNewSubscription(token, accId, email, plan)
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

func handleNewSubscription(token, accId, email string, plan *paymentmodels.Plan) error {
	customer, err := CreateCustomer(token, accId, email)
	if err != nil {
		return err
	}

	_, err = CreateSubscription(customer, plan)
	if err != nil {
		deleteCustomer(customer)
		return err
	}

	return nil
}

func handleUserNoSub(customer *paymentmodels.Customer, token string, plan *paymentmodels.Plan) error {
	if token != "" {
		err := UpdateCreditCard(customer.OldId, token)
		if err != nil {
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
		err = CancelSubscription(customer, &sub)
		if err != nil {
			Log.Error(err.Error())
		}
	}

	return nil
}

func deleteCustomer(customer *paymentmodels.Customer) {
	removeCreditCardHelper(customer)

	err := stripeCustomer.Del(customer.ProviderCustomerId)
	if err != nil {
		Log.Error("Error deleting customer from Stripe: %v", err)
	}

	err = customer.Delete()
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
