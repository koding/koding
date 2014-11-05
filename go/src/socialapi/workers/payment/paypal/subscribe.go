package paypal

import (
	"errors"
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"
	"strings"
)

func Subscribe(token, accId string) error {
	plan, err := FindPlanFromToken(token)
	if err != nil {
		return err
	}

	customer, err := FindCustomerByOldId(accId)
	if err != nil && err != paymenterrors.ErrCustomerNotFound {
		return err
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
		err = handleCancelation(token, customer, plan)
	case Downgrade:
		err = handleDowngrade(token, customer, plan)
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

func handleCancelation(token string, customer *paymentmodels.Customer, plan *paymentmodels.Plan) error {
	return nil
}

func handleDowngrade(token string, customer *paymentmodels.Customer, plan *paymentmodels.Plan) error {
	return nil
}

func handleUpgrade(token string, customer *paymentmodels.Customer, plan *paymentmodels.Plan) error {
	return errors.New("upgrades are disabled for paypal")
}

func parsePlanInfo(str string) (string, string) {
	split := strings.Split(str, "-")
	planTitle, planInterval := split[0], split[1]

	return planTitle, planInterval
}
