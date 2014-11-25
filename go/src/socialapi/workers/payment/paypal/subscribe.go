package paypal

import (
	"errors"
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"
	"socialapi/workers/payment/stripe"
	"strings"

	"github.com/koding/paypal"
)

func SubscribeWithPlan(token, accId, planTitle, planInterval string) error {
	plan, err := stripe.FindPlanByTitleAndInterval(planTitle, planInterval)
	if err != nil {
		return err
	}

	return subscribe(token, accId, plan)
}

func Subscribe(token, accId string) error {
	plan, err := FindPlanFromToken(token)
	if err != nil {
		return err
	}

	return subscribe(token, accId, plan)
}

func subscribe(token, accId string, plan *paymentmodels.Plan) error {
	customer, err := FindCustomerByOldId(accId)
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

	status, err := checkStatus(customer, err, plan)
	if err != nil {
		Log.Error("Subscribing to %s failed for user: %s", plan.Title, customer.Username)
		return err
	}

	switch status {
	case AlreadySubscribedToPlan:
		err = paymenterrors.ErrCustomerAlreadySubscribedToPlan
	case NewSubscription:
		err = handleNewSubscription(token, accId, plan)
	case ExistingUserHasNoSubscription:
		err = handleExistingUser(token, accId, plan)
	case DowngradeToFreePlan:
		err = handleCancelation(customer, subscription)
	case Downgrade:
		err = handleDowngrade(customer, plan, subscription)
	case Upgrade:
		err = handleUpgrade(token, customer, plan)
	default:
		Log.Error("User: %s fell into default case when subscribing: %s", customer.Username, plan.Title)
		// user should never come here
	}

	return err
}

func handleNewSubscription(token, accId string, plan *paymentmodels.Plan) error {
	customer, err := CreateCustomer(accId)
	if err != nil {
		return err
	}

	return CreateSubscription(token, plan, customer)
}

func handleExistingUser(token, accId string, plan *paymentmodels.Plan) error {
	customer, err := FindCustomerByOldId(accId)
	if err != nil {
		return err
	}

	return CreateSubscription(token, plan, customer)
}

func handleCancelation(customer *paymentmodels.Customer, subscription *paymentmodels.Subscription) error {
	client, err := Client()
	if err != nil {
		return err
	}

	response, err := client.ManageRecurringPaymentsProfileStatus(
		customer.ProviderCustomerId, paypal.Cancel,
	)
	err = handlePaypalErr(response, err)
	if err != nil {
		return err
	}

	return subscription.Cancel()
}

func handleDowngrade(customer *paymentmodels.Customer, plan *paymentmodels.Plan, subscription *paymentmodels.Subscription) error {
	params := map[string]string{
		"AMT": normalizeAmount(plan.AmountInCents),
		"L_PAYMENTREQUEST_0_NAME0": goodName(plan),
	}

	client, err := Client()
	if err != nil {
		return err
	}

	resp, err := client.UpdateRecurringPaymentsProfile(customer.ProviderCustomerId, params)
	err = handlePaypalErr(resp, err)
	if err != nil {
		return err
	}

	return subscription.UpdatePlan(plan.Id, plan.AmountInCents)
}

func handleUpgrade(token string, customer *paymentmodels.Customer, plan *paymentmodels.Plan) error {
	return errors.New("upgrades are disabled for paypal")
}

func parsePlanInfo(str string) (string, string) {
	split := strings.Split(str, " ")

	if len(split) < 2 {
		Log.Error("PlanInfo from paypal is wrong: %s", str)
	}

	planTitle := strings.ToLower(split[0])
	planInterval := strings.ToLower(split[1])

	return planTitle, planInterval
}
