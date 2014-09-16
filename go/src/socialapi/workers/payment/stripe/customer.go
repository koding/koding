package stripe

import (
	"socialapi/models/paymentmodel"

	stripe "github.com/stripe/stripe-go"
	stripeCustomer "github.com/stripe/stripe-go/customer"
)

// Creates customer in Stripe and saves customer with Stripe's customer_id;
// token is previously acquired from Stripe, represents customer's cc info;
// accId is the `jAccount` id from mongo.
func CreateCustomer(token, accId, email string) (*paymentmodel.Customer, error) {
	params := &stripe.CustomerParams{
		Desc:  accId,
		Email: email,
	}

	stripeCustomer, err := stripeCustomer.Create(params)
	if err != nil {
		return nil, err
	}

	customerModel := paymentmodel.NewCustomer(
		accId, stripeCustomer.Id, ProviderName,
	)

	err = customerModel.Create()
	if err != nil {
		return nil, err
	}

	return customerModel, nil
}

func FindCustomerByOldId(oldId string) (*paymentmodel.Customer, error) {
	customerModel := &paymentmodel.Customer{
		OldId: oldId,
	}

	exists, err := customerModel.ByOldId()
	if err != nil {
		return nil, err
	}

	if !exists {
		return nil, nil
	}

	return customerModel, nil
}
