package payment

import (
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"
	"socialapi/workers/payment/paypal"
	"socialapi/workers/payment/stripe"
)

//----------------------------------------------------------
// AccountSubscribe
//----------------------------------------------------------

type AccountSubscribeRequest struct {
	AccountId string
	SubscribeRequest
}

func (a *AccountSubscribeRequest) Do() (interface{}, error) {
	var err error

	switch a.Provider {
	case "stripe":
		err = stripe.SubscribeForAccount(a.Token, a.AccountId, a.Email, a.PlanTitle, a.PlanInterval)
	case "paypal":
		err = paypal.SubscribeWithPlan(a.Token, a.AccountId, a.PlanTitle, a.PlanInterval)
	default:
		err = ErrProviderNotFound
	}

	return nil, err
}

//----------------------------------------------------------
// AccountSubscriptions
//----------------------------------------------------------

type AccountRequest struct {
	AccountId string
}

type AccountSubscriptionResponse struct {
	AccountId string `json:"accountId"`
	SubscriptionResponse
}

// Subscriptions return given `account_id` subscription if it exists.
// In case of no customer, or no subscriptions or no plan found, it
// returns the default plan as subscription.
func (a *AccountRequest) Subscriptions() (*AccountSubscriptionResponse, error) {
	if a.AccountId == "" {
		return nil, paymenterrors.ErrAccountIdIsNotSet
	}

	defaultResp := &AccountSubscriptionResponse{
		AccountId: a.AccountId,
		SubscriptionResponse: SubscriptionResponse{
			PlanTitle:    "free",
			PlanInterval: "month",
			State:        "active",
			Provider:     "koding",
		},
	}

	resp, err := findSubscription(a.AccountId)
	if err != nil {
		return defaultResp, nil
	}

	return &AccountSubscriptionResponse{
		AccountId:            a.AccountId,
		SubscriptionResponse: resp,
	}, nil
}

func (a *AccountRequest) Delete() (interface{}, error) {
	return nil, stripe.DeleteCustomer(a.AccountId)
}

func (a *AccountRequest) Invoices() ([]*stripe.StripeInvoiceResponse, error) {
	return stripe.FindInvoicesForCustomer(a.AccountId)
}

func (a *AccountRequest) GetCreditCard() (*stripe.CreditCardResponse, error) {
	return stripe.GetCreditCard(a.AccountId)
}

func (a *AccountRequest) ActiveUsernames() ([]string, error) {
	customer := paymentmodels.NewCustomer()
	customers, err := customer.ByActiveSubscription()
	if err != nil {
		return nil, err
	}

	usernames := []string{}
	for _, customer := range customers {
		if customer.Username != "" {
			usernames = append(usernames, customer.Username)
		}
	}

	return usernames, nil
}

func (a *AccountRequest) Expire() (interface{}, error) {
	customer, err := paymentmodels.NewCustomer().ByOldId(a.AccountId)
	if err != nil {
		return nil, err
	}

	subscription, err := customer.FindActiveSubscription()
	if err != nil {
		return nil, err
	}

	return nil, subscription.Expire()
}

func (a *AccountRequest) CancelSubscription() (interface{}, error) {
	return nil, cancelSubscription(a.AccountId)
}

//----------------------------------------------------------
// AccountUpdateCreditCard
//----------------------------------------------------------

type AccountUpdateCreditCardRequest struct {
	AccountId string
	UpdateCreditCardRequest
}

func (a *AccountUpdateCreditCardRequest) Do() (interface{}, error) {
	switch a.Provider {
	case "stripe":
		err := stripe.UpdateCreditCard(a.AccountId, a.Token)
		if err != nil {
			Log.Error("Updating cc for account: %s failed. %s", a.AccountId, err)
		}

		return nil, err
	case "paypal":
		return nil, ErrProviderNotImplemented
	default:
		return nil, ErrProviderNotFound
	}
}
