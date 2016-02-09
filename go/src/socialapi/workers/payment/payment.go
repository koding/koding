package payment

import (
	"errors"
	"socialapi/workers/payment/paymentmodels"
	"socialapi/workers/payment/paypal"
	"socialapi/workers/payment/stripe"
	"time"

	"github.com/koding/runner"

	"github.com/koding/kite"
)

var (
	ErrProviderNotFound       = errors.New("provider not found")
	ErrProviderNotImplemented = errors.New("provider not implemented")

	ErrNoGroupForPaypal = errors.New("Paypal does not support group purchases currently.")

	WorkerName    = "socialapi-payment"
	WorkerVersion = "1.0.0"

	Log = runner.CreateLogger(WorkerName, false)

	KiteClient *kite.Client
)

type SubscribeRequest struct {
	Token        string
	Email        string
	Provider     string
	PlanTitle    string
	PlanInterval string
}

type SubscriptionResponse struct {
	PlanTitle          string    `json:"planTitle"`
	PlanInterval       string    `json:"planInterval"`
	State              string    `json:"state"`
	Provider           string    `json:"provider"`
	ExpiredAt          time.Time `json:"expiredAt"`
	CanceledAt         time.Time `json:"canceledAt"`
	CurrentPeriodStart time.Time `json:"currentPeriodStart"`
	CurrentPeriodEnd   time.Time `json:"currentPeriodEnd"`
}

//----------------------------------------------------------
// Account
//----------------------------------------------------------

func (a *AccountRequest) Invoices() ([]*stripe.StripeInvoiceResponse, error) {
	return stripe.FindInvoicesForCustomer(a.AccountId)
}

func (a *AccountRequest) CreditCard() (*stripe.CreditCardResponse, error) {
	return stripe.GetCreditCard(a.AccountId)
}

func (a *AccountRequest) Delete() (interface{}, error) {
	return nil, stripe.DeleteCustomer(a.AccountId)
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

//----------------------------------------------------------
// UpdateCreditCard
//----------------------------------------------------------

type UpdateCreditCardRequest struct {
	AccountId, Provider, Token string
}

func (u *UpdateCreditCardRequest) Do() (interface{}, error) {
	switch u.Provider {
	case "stripe":
		err := stripe.UpdateCreditCard(u.AccountId, u.Token)
		if err != nil {
			Log.Error("Updating cc for account: %s failed. %s", u.AccountId, err)
		}

		return nil, err
	case "paypal":
		return nil, ErrProviderNotImplemented
	default:
		return nil, ErrProviderNotFound
	}
}

//----------------------------------------------------------
// Paypal
//----------------------------------------------------------

type PaypalRequest struct {
	Token     string `json:"token"`
	AccountId string `json:"accountId"`
}

func (p *PaypalRequest) Success() (interface{}, error) {
	return nil, paypal.Subscribe(p.Token, p.AccountId)
}

func (p *PaypalRequest) Cancel() (interface{}, error) {
	return nil, nil
}

type PaypalGetTokenRequest struct {
	PlanTitle    string `json:"planTitle"`
	PlanInterval string `json:"planInterval"`
}

func (p *PaypalGetTokenRequest) Do() (interface{}, error) {
	return paypal.GetToken(p.PlanTitle, p.PlanInterval, paymentmodels.AccountCustomer)
}

//----------------------------------------------------------
// Helpers
//----------------------------------------------------------

func findSubscription(id string) (SubscriptionResponse, error) {
	customer, err := paymentmodels.NewCustomer().ByOldId(id)
	if err != nil {
		return SubscriptionResponse{}, err
	}

	subscriptions, err := stripe.FindCustomerSubscriptions(customer)
	if err != nil {
		return SubscriptionResponse{}, err
	}

	if len(subscriptions) == 0 {
		return SubscriptionResponse{}, errors.New("no subscription found")
	}

	currentSubscription := subscriptions[0]

	// cancel implies user took the action after satisfying provider limits,
	// therefore we return `free` plan for them
	if currentSubscription.State == paymentmodels.SubscriptionStateCanceled {
		return SubscriptionResponse{}, errors.New("subscription is canceled")
	}

	plan := &paymentmodels.Plan{}
	if err := plan.ById(currentSubscription.PlanId); err != nil {
		return SubscriptionResponse{}, err
	}

	return SubscriptionResponse{
		PlanTitle:          plan.Title,
		PlanInterval:       plan.Interval,
		CurrentPeriodStart: currentSubscription.CurrentPeriodStart,
		CurrentPeriodEnd:   currentSubscription.CurrentPeriodEnd,
		State:              currentSubscription.State,
		Provider:           currentSubscription.Provider,
		ExpiredAt:          currentSubscription.ExpiredAt,
		CanceledAt:         currentSubscription.CanceledAt,
	}, nil
}
