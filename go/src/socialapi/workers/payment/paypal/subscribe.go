package paypal

import "socialapi/workers/payment/paymenterrors"

func Subscribe(token, accId, email, planTitle, planInterval string) error {
	customer, err := FindCustomerByOldId(accId)
	if err != nil && err != paymenterrors.ErrCustomerNotFound {
		return err
	}

	if err == paymenterrors.ErrCustomerNotFound {
		customer, err = CreateCustomer(accId, email)
		if err != nil {
			return err
		}
	}

	plan, err := FindPlanByTitleAndInterval(planTitle, planInterval)
	if err != nil {
		return err
	}

	return CreateSubscription(token, plan, customer)
}
