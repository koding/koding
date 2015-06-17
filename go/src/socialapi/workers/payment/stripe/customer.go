package stripe

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"

	stripe "github.com/stripe/stripe-go"
	stripeCustomer "github.com/stripe/stripe-go/customer"
)

// CreateCustomer creates customer in Stripe and saves customer with
// Stripe's customer_id; token is previously acquired from Stripe,
// represents customer's cc info; accId is the `jAccount` id from mongo.
func CreateCustomer(token, accId, email string) (*paymentmodels.Customer, error) {
	if IsEmpty(token) {
		return nil, paymenterrors.ErrTokenIsEmpty
	}

	params := &stripe.CustomerParams{
		Desc:  accId,
		Email: email,
		Token: token,
	}

	account, err := modelhelper.GetAccountById(accId)
	if err == nil {
		params.Meta = map[string]string{
			"username":  account.Profile.Nickname,
			"createdAt": account.Meta.CreatedAt.String(),
			"status":    account.Status,
			"firstName": account.Profile.FirstName,
			"lastName":  account.Profile.LastName,
		}
	}

	if err != nil {
		Log.Error("Fetching account: %s failed. %s", accId, err)
	}

	externalCustomer, err := stripeCustomer.New(params)
	if err != nil {
		return nil, handleStripeError(err)
	}

	customerModel := &paymentmodels.Customer{
		OldId:              accId,
		ProviderCustomerId: externalCustomer.Id,
		Provider:           ProviderName,
		Username:           account.Profile.Nickname,
	}

	err = customerModel.Create()

	return customerModel, err
}

func GetCustomer(id string) (*stripe.Customer, error) {
	customer, err := stripeCustomer.Get(id, nil)
	if err != nil {
		return nil, handleStripeError(err)
	}

	return customer, nil
}

func DeleteCustomer(accId string) error {
	customer, err := paymentmodels.NewCustomer().ByOldId(accId)
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

	return stripeCustomer.Del(customer.ProviderCustomerId)
}
