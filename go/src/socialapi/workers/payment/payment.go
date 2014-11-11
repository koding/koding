package payment

import (
	"encoding/json"
	"errors"
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"
	"socialapi/workers/payment/paypal"
	"socialapi/workers/payment/stripe"
	"time"

	"github.com/koding/logging"
)

var (
	ProviderNotFound       = errors.New("provider not found")
	ProviderNotImplemented = errors.New("provider not implemented")
	Log                    = logging.NewLogger("payment")
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

	customer, err := stripe.FindCustomerByOldId(a.AccountId)
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
	}

	return resp, nil
}

func (a *AccountRequest) Invoices() ([]*stripe.StripeInvoiceResponse, error) {
	invoices, err := stripe.FindInvoicesForCustomer(a.AccountId)
	if err != nil {
		Log.Error("Fetching invoices for account: %s failed. %s", a.AccountId, err)
	}

	return invoices, err
}

func (a *AccountRequest) CreditCard() (*stripe.CreditCardResponse, error) {
	resp, err := stripe.GetCreditCard(a.AccountId)
	if err != nil {
		Log.Error("Fetching cc for account: %s failed. %s", a.AccountId, err)
	}

	return resp, err
}

func (a *AccountRequest) Delete() (interface{}, error) {
	err := stripe.DeleteCustomer(a.AccountId)
	if err != nil {
		Log.Error("Deleting account: %s failed. %s", a.AccountId, err)
	}

	return nil, err
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
		Log.Error("Received test Stripe webhook: %v", s)
		return nil, nil
	}

	raw, err := json.Marshal(s.Data.Object)
	if err != nil {
		Log.Error("Error marshalling Stripe webhook '%v' : %v", s, err)
		return nil, err
	}

	switch s.Name {
	case "customer.subscription.deleted":
		err = stripe.SubscriptionDeletedWebhook(raw)
	case "invoice.created":
		err = stripe.InvoiceCreatedWebhook(raw)
	}

	if err != nil {
		Log.Error("Error handling Stripe webhook '%v' : %v", s, err)
	}

	return nil, err
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

//----------------------------------------------------------
// Webhook
//----------------------------------------------------------

type PaypalWebhook struct {
	Status  string `json:"payment_status"`
	PayerId string `json:"payer_id"`
}

var PaypalActionCancel = "cancel"

var PaypalStatusActionMap = map[string]string{
	"Denied":   PaypalActionCancel,
	"Expired":  PaypalActionCancel,
	"Failed":   PaypalActionCancel,
	"Reversed": PaypalActionCancel,
	"Voided":   PaypalActionCancel,
}

func (p *PaypalWebhook) Do() (interface{}, error) {
	action, ok := PaypalStatusActionMap[p.Status]
	if !ok {
		return nil, nil
	}

	var err error

	switch action {
	case PaypalActionCancel:
		err = paypal.CancelSubscription(p.PayerId)
	}

	return nil, err
}
