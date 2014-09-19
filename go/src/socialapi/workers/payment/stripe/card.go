package stripe

import (
	stripe "github.com/stripe/stripe-go"
	stripeCustomer "github.com/stripe/stripe-go/customer"
)

func UpdateCreditCard(oldId, token string) error {
	customer, err := FindCustomerByOldId(oldId)
	if err != nil {
		return err
	}

	customerParams := &stripe.CustomerParams{Token: token}

	_, err = stripeCustomer.Update(customer.ProviderCustomerId, customerParams)
	if err != nil {
		return err
	}

	return nil
}
