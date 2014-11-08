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

	return _subscribe(token, accId, plan)
}

func Subscribe(token, accId string) error {
	plan, err := FindPlanFromToken(token)
	if err != nil {
		return err
	}

	return _subscribe(token, accId, plan)
}

func _subscribe(token, accId string, plan *paymentmodels.Plan) error {
	customer, err := FindCustomerByOldId(accId)
	if err != nil && err != paymenterrors.ErrCustomerNotFound {
		return err
	}

	var subscription *paymentmodels.Subscription
	if customer != nil {
		subscription, err = customer.FindActiveSubscription()
		if err != nil {
			return err
		}
	}

	status, err := checkStatus(customer, err, plan)
	if err != nil {
		return err
	}

	switch status {
	case AlreadySubscribedToPlan:
		err = paymenterrors.ErrCustomerAlreadySubscribedToPlan
	case NewSubscription:
		err = handleNewSubscription(token, accId, plan)
	case DowngradeToFreePlan:
		err = handleCancelation(customer, subscription)
	case Downgrade:
		err = handleDowngrade(customer, plan, subscription)
	case Upgrade:
		err = handleUpgrade(token, customer, plan)
	default:
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
	split := strings.Split(str, "-")
	planTitle, planInterval := split[0], split[1]

	return planTitle, planInterval
}
