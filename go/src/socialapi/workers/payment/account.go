package payment

import (
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paypal"
	"socialapi/workers/payment/stripe"
)

//----------------------------------------------------------
// AccountSubscribe
//----------------------------------------------------------

type AccountSubscribeRequest struct {
	AccountId string `json:"accountId"`
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

//----------------------------------------------------------
// AccountUpdateCreditCard
//----------------------------------------------------------

type AccountUpdateCreditCardRequest struct {
	AccountId string `json:"accountId"`
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
