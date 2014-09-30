package payment

import (
	"encoding/json"
	"errors"
	"fmt"
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"
	"socialapi/workers/payment/stripe"
	"time"
)

var (
	ProviderNotFound       = errors.New("provider not found")
	ProviderNotImplemented = errors.New("provider not implemented")
)

//----------------------------------------------------------
// SubscribeRequest
//----------------------------------------------------------

type SubscribeRequest struct {
	AccountId, Token, Email           string
	Provider, PlanTitle, PlanInterval string
}

func (s *SubscribeRequest) Do() (interface{}, error) {
	switch s.Provider {
	case "stripe":
		return nil, stripe.Subscribe(
			s.Token, s.AccountId, s.Email, s.PlanTitle, s.PlanInterval,
		)
	case "paypal":
		return nil, ProviderNotImplemented
	default:
		return nil, ProviderNotFound
	}
}

//----------------------------------------------------------
// AccountRequest
//----------------------------------------------------------

type AccountRequest struct {
	AccountId string
}

type SubscriptionsResponse struct {
	AccountId          string    `json:"accountId"`
	PlanTitle          string    `json:"planTitle"`
	PlanInterval       string    `json:"planInterval"`
	State              string    `json:"state"`
	CurrentPeriodStart time.Time `json:"currentPeriodStart"`
	CurrentPeriodEnd   time.Time `json:"currentPeriodEnd"`
}

// Do checks if given `account_id` is a paying customer and returns
// the current plan the current is subscribed if any.
//
// Errors:
//		paymenterrors.ErrCustomerNotFound if user is found
//		paymenterrors.ErrCustomerNotSubscribedToAnyPlans if user no subscriptions
//		paymenterrors.ErrPlanNotFound if user subscription's plan isn't found
func (a *AccountRequest) Subscriptions() (*SubscriptionsResponse, error) {
	if a.AccountId == "" {
		return nil, paymenterrors.ErrAccountIdIsNotSet
	}

	customer, err := stripe.FindCustomerByOldId(a.AccountId)
	if err != nil {
		return nil, err
	}

	subscriptions, err := stripe.FindCustomerActiveSubscriptions(customer)
	if err != nil {
		return nil, err
	}

	if len(subscriptions) == 0 {
		return nil, paymenterrors.ErrCustomerNotSubscribedToAnyPlans
	}

	currentSubscription := subscriptions[0]

	plan := &paymentmodel.Plan{}
	err = plan.ById(currentSubscription.PlanId)
	if err != nil {
		return nil, err
	}

	resp := &SubscriptionsResponse{
		AccountId:          a.AccountId,
		PlanTitle:          plan.Title,
		PlanInterval:       plan.Interval,
		CurrentPeriodStart: currentSubscription.CurrentPeriodStart,
		CurrentPeriodEnd:   currentSubscription.CurrentPeriodEnd,
		State:              currentSubscription.State,
	}

	return resp, nil
}

// DoWithDefault is different from Do since client excepts to get
// "free" plan regardless of user not found or doesn't have any
// subscriptions etc.
func (a *AccountRequest) DoWithDefault() (*SubscriptionsResponse, error) {
	resp, err := a.Subscriptions()
	if err == nil {
		return resp, nil
	}

	defaultResp := &SubscriptionsResponse{
		AccountId:    a.AccountId,
		PlanTitle:    "free",
		PlanInterval: "month",
		State:        "active",
	}

	defaultResponseErrs := []error{
		paymenterrors.ErrCustomerNotSubscribedToAnyPlans,
		paymenterrors.ErrCustomerNotFound,
		paymenterrors.ErrPlanNotFound,
	}

	for _, respError := range defaultResponseErrs {
		if err == respError {
			return defaultResp, nil
		}
	}

	return nil, err
}

func (a *AccountRequest) Invoices() ([]*stripe.StripeInvoiceResponse, error) {
	invoices, err := stripe.FindInvoicesForCustomer(a.AccountId)
	if err != nil {
		return nil, err
	}

	return invoices, nil
}

func (a *AccountRequest) CreditCard() (*stripe.CreditCardResponse, error) {
	resp, err := stripe.GetCreditCard(a.AccountId)
	if err != nil {
		return nil, err
	}

	return resp, nil
}

func (a *AccountRequest) Delete() (interface{}, error) {
	return nil, nil
}

//----------------------------------------------------------
// UpdateCreditCard
//----------------------------------------------------------

type UpdateCreditCardRequest struct {
	AccountId, Provider, Token string
}

func (u *UpdateCreditCardRequest) Do() (interface{}, error) {
	switch u.Provider {
	case "stripe":
		return nil, stripe.UpdateCreditCard(u.AccountId, u.Token)
	case "paypal":
		return nil, ProviderNotImplemented
	default:
		return nil, ProviderNotFound
	}
}

//----------------------------------------------------------
// StripeWebhook
//----------------------------------------------------------

type StripeWebhook struct {
	Name     string `json:"type"`
	Created  int    `json:"created"`
	Livemode bool   `json:"livemode"`
	Id       string `json:"id"`
	Data     struct {
		Object interface{} `json:"object"`
	} `json:"data"`
}

func (s *StripeWebhook) Do() (interface{}, error) {
	var err error

	if !s.Livemode {
		return nil, nil
	}

	switch s.Name {
	case "customer.subscription.deleted":
		raw, err := json.Marshal(s.Data.Object)
		if err != nil {
			return nil, err
		}

		err = stripe.SubscriptionDeletedWebhook(raw)
	default:
		fmt.Println("Unhandled Stripe webhook", s.Name)
	}

	return nil, err
}
