package paypal

import (
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"
)

func Subscribe(token, accId, email, planTitle, planInterval string) error {
	plan, err := FindPlanByTitleAndInterval(planTitle, planInterval)
	if err != nil {
		return err
	}

	_, err = FindCustomerByOldId(accId)
	if err != nil && err != paymenterrors.ErrCustomerNotFound {
		return err
	}

	if err == paymenterrors.ErrCustomerNotFound {
		err = handlNewSubscription(token, accId, email, plan)
		return err
	}

	return nil
}

func handlNewSubscription(token, accId, email string, plan *paymentmodels.Plan) error {
	customer, err := CreateCustomer(accId, email)
	if err != nil {
		return err
	}

	return CreateSubscription(token, plan, customer)
}
