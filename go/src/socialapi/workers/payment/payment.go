package payment

import (
	"errors"
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"
	"socialapi/workers/payment/paypal"
	"socialapi/workers/payment/stripe"
	"time"

	"github.com/koding/runner"

	"github.com/koding/kite"
)

var (
	ProviderNotFound       = errors.New("provider not found")
	ProviderNotImplemented = errors.New("provider not implemented")

	WorkerName    = "socialapi-payment"
	WorkerVersion = "1.0.0"

	Log = runner.CreateLogger(WorkerName, false)

	KiteClient *kite.Client
)

//----------------------------------------------------------
// SubscribeRequest
//----------------------------------------------------------

type SubscribeRequest struct {
	AccountId, Token, Email           string
	Provider, PlanTitle, PlanInterval string
}

func (s *SubscribeRequest) Do() (interface{}, error) {
	var err error

	switch s.Provider {
	case "stripe":
		err = stripe.Subscribe(
			s.Token, s.AccountId, s.Email, s.PlanTitle, s.PlanInterval,
		)
	case "paypal":
		err = paypal.SubscribeWithPlan(s.Token, s.AccountId, s.PlanTitle, s.PlanInterval)
	default:
		err = ProviderNotFound
	}

	if err != nil {
		Log.Error(
			"Subscribing account: %s to plan: %s failed. %s",
			s.AccountId, s.PlanTitle, err,
		)
	}

	return nil, err
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
	Provider           string    `json:"provider"`
	ExpiredAt          time.Time `json:"expiredAt"`
	CanceledAt         time.Time `json:"canceledAt"`
	CurrentPeriodStart time.Time `json:"currentPeriodStart"`
	CurrentPeriodEnd   time.Time `json:"currentPeriodEnd"`
}

// Subscriptions return given `account_id` subscription if it exists.
// In case of no customer, or no subscriptions or no plan found, it
// returns the default plan as subscription.
func (a *AccountRequest) Subscriptions() (*SubscriptionsResponse, error) {
	if a.AccountId == "" {
		return nil, paymenterrors.ErrAccountIdIsNotSet
	}

	defaultResp := &SubscriptionsResponse{
		AccountId:    a.AccountId,
		PlanTitle:    "free",
		PlanInterval: "month",
		State:        "active",
		Provider:     "koding",
	}

	customer, err := paymentmodels.NewCustomer().ByOldId(a.AccountId)
	if err != nil {
		return defaultResp, nil
	}

	subscriptions, err := stripe.FindCustomerSubscriptions(customer)
	if err != nil {
		return defaultResp, nil
	}

	if len(subscriptions) == 0 {
		return defaultResp, nil
	}

	currentSubscription := subscriptions[0]

	// cancel implies user took the action after satisfying provider limits,
	// therefore we return `free` plan for them
	if currentSubscription.State == paymentmodels.SubscriptionStateCanceled {
		return defaultResp, nil
	}

	plan := &paymentmodels.Plan{}
	err = plan.ById(currentSubscription.PlanId)
	if err != nil {
		return defaultResp, nil
	}

	resp := &SubscriptionsResponse{
		AccountId:          a.AccountId,
		PlanTitle:          plan.Title,
		PlanInterval:       plan.Interval,
		CurrentPeriodStart: currentSubscription.CurrentPeriodStart,
		CurrentPeriodEnd:   currentSubscription.CurrentPeriodEnd,
		State:              currentSubscription.State,
		Provider:           currentSubscription.Provider,
		ExpiredAt:          currentSubscription.ExpiredAt,
		CanceledAt:         currentSubscription.CanceledAt,
	}

	return resp, nil
}

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
		return nil, ProviderNotImplemented
	default:
		return nil, ProviderNotFound
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
	return paypal.GetToken(p.PlanTitle, p.PlanInterval)
}
