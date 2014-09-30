package stripe

import (
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"

	stripe "github.com/stripe/stripe-go"
	stripeCustomer "github.com/stripe/stripe-go/customer"
)

// CreateCustomer creates customer in Stripe and saves customer with
// Stripe's customer_id; token is previously acquired from Stripe,
// represents customer's cc info; accId is the `jAccount` id from mongo.
func CreateCustomer(token, accId, email string) (*paymentmodel.Customer, error) {
	if IsEmpty(token) {
		return nil, paymenterrors.ErrTokenIsEmpty
	}

	params := &stripe.CustomerParams{
		Desc:  accId,
		Email: email,
		Token: token,
	}

	externalCustomer, err := stripeCustomer.New(params)
	if err != nil {
		return nil, handleStripeError(err)
	}

	customerModel := &paymentmodel.Customer{
		OldId:              accId,
		ProviderCustomerId: externalCustomer.Id,
		Provider:           ProviderName,
	}

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
		return nil, paymenterrors.ErrCustomerNotFound
	}

	return customerModel, nil
}

func GetCustomer(id string) (*stripe.Customer, error) {
	customer, err := stripeCustomer.Get(id, nil)
	if err != nil {
		return nil, handleStripeError(err)
	}

	return customer, nil
}

func DeleteCustomer(accId string) error {
	customer := paymentmodel.NewCustomer()
	err := customer.FindByOldId(accId)
	if err != nil {
		return err
	}

	currentSubscription, err := customer.FindActiveSubscription()
	if err != nil {
		return err
	}

	err = CancelSubscriptionAndRemoveCC(customer, currentSubscription)
	if err != nil {
		return err
	}

	err = stripeCustomer.Del(customer.ProviderCustomerId)

	return err
}
