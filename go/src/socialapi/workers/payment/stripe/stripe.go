package stripe

import (
	"socialapi/models/paymentmodel"

	"github.com/stripe/stripe-go"
	stripeCustomer "github.com/stripe/stripe-go/customer"
)

var (
	ProviderName = "Stripe"
)

func init() {
	stripe.Key = "sk_test_VSkGDktXmmxl0MvXajOBxYGm"
}

//----------------------------------------------------------
// Customer
//----------------------------------------------------------

func CreateCustomer(username, email string) (*paymentmodel.Customer, error) {
	params := &stripe.CustomerParams{
		Desc:  username,
		Email: email,
	}

	stripeCustomer, err := stripeCustomer.Create(params)
	if err != nil {
		return nil, err
	}

	customerModel := paymentmodel.NewCustomer(
		username, stripeCustomer.Id, ProviderName,
	)

	err = customerModel.Create()
	if err != nil {
		return nil, err
	}

	return customerModel, nil
}
