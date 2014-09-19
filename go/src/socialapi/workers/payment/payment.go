package payment

import (
	"errors"
	"fmt"
	"socialapi/models/paymentmodel"
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
// SubscriptionRequest
//----------------------------------------------------------

type SubscriptionRequest struct {
	AccountId string
}

type SubscriptionsResponse struct {
	PlanTitle          string    `json:"planTitle"`
	PlanInterval       string    `json:"planInterval"`
	State              string    `json:"state"`
	CreatedAt          time.Time `json:"createdAt"`
	CanceledAt         time.Time `json:"canceledAt"`
	CurrentPeriodStart time.Time `json:"currentPeriodStart"`
	CurrentPeriodEnd   time.Time `json:"currentPeriodEnd"`
	AcccountId         string    `json:"acccountId"`
}

func (s *SubscriptionRequest) Do() (*SubscriptionsResponse, error) {
	resp := &SubscriptionsResponse{
		AcccountId:   s.AccountId,
		PlanTitle:    "free",
		PlanInterval: "month",
	}

	customer, err := stripe.FindCustomerByOldId(s.AccountId)
	if err == stripe.ErrCustomerNotFound {
		return resp, nil
	}

	if err != nil {
		return nil, err
	}

	subscriptions, err := stripe.FindCustomerActiveSubscriptions(customer)
	if err != nil {
		return nil, err
	}

	if len(subscriptions) == 0 {
		return resp, nil
	}

	currentSubscription := subscriptions[0]

	plan := &paymentmodel.Plan{}
	err = plan.ById(currentSubscription.PlanId)
	if err != nil {
		return nil, err
	}

	resp.PlanTitle = plan.Title
	resp.PlanInterval = plan.Interval
	resp.CurrentPeriodStart = currentSubscription.CurrentPeriodStart
	resp.CurrentPeriodEnd = currentSubscription.CurrentPeriodEnd
	resp.State = currentSubscription.State

	return resp, nil
}

//----------------------------------------------------------
// Stripe Webhook
//----------------------------------------------------------

type StripeWebhook struct {
	Name     string      `json:"type"`
	Created  int         `json:"created"`
	Livemode bool        `json:"livemode"`
	Id       string      `json:"id"`
	Data     interface{} `json:"data"`
	Object   string      `json:"object"`
}

func (s *StripeWebhook) Do() (interface{}, error) {
	switch s.Name {
	case "charge.failed":
		fmt.Println(">>>>>>>>>>> charge.failed")
	case "charge.dispute.created":
		fmt.Println(">>>>>>>>>>> charge.dispute.created")
	case "invoice.payment_failed":
		fmt.Println(">>>>>>>>>>> invoice.payment_failed")
	case "transfer.failed":
		fmt.Println(">>>>>>>>>>> transfer.failed")
	default:
		fmt.Println(">>>>>>>>>, unknown webhook", s.Name)
	}

	return nil, nil
}
