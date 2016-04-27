package payment

import (
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/stripe"
)

//----------------------------------------------------------
// GroupSubscribe
//----------------------------------------------------------

type GroupSubscribeRequest struct {
	GroupId string
	SubscribeRequest
}

func (g *GroupSubscribeRequest) Do() (interface{}, error) {
	var err error

	switch g.Provider {
	case "stripe":
		err = stripe.SubscribeForGroup(g.Token, g.GroupId, g.Email, g.PlanTitle, g.PlanInterval)
	case "paypal":
		err = ErrNoGroupForPaypal
	default:
		err = ErrProviderNotFound
	}

	return nil, err
}

//----------------------------------------------------------
// GroupRequest
//----------------------------------------------------------

type GroupRequest struct {
	GroupId string
}

type GroupSubscriptionResponse struct {
	GroupId string `json:"groupId"`
	SubscriptionResponse
}

func (g *GroupRequest) Subscriptions() (*GroupSubscriptionResponse, error) {
	if g.GroupId == "" {
		return nil, paymenterrors.ErrGroupIdNotSet
	}

	defaultResp := &GroupSubscriptionResponse{
		GroupId: g.GroupId,
		SubscriptionResponse: SubscriptionResponse{
			PlanTitle:    "free",
			PlanInterval: "month",
			State:        "active",
			Provider:     "koding",
		},
	}

	resp, err := findSubscription(g.GroupId)
	if err != nil {
		return defaultResp, nil
	}

	return &GroupSubscriptionResponse{
		GroupId:              g.GroupId,
		SubscriptionResponse: resp,
	}, nil
}

func (g *GroupRequest) Delete() (interface{}, error) {
	return nil, stripe.DeleteCustomer(g.GroupId)
}

func (g *GroupRequest) Invoices() ([]*stripe.StripeInvoiceResponse, error) {
	return stripe.FindInvoicesForCustomer(g.GroupId)
}

func (g *GroupRequest) GetCreditCard() (*stripe.CreditCardResponse, error) {
	return stripe.GetCreditCard(g.GroupId)
}

func (g *GroupRequest) GetInvoices() ([]*stripe.StripeInvoiceResponse, error) {
	return stripe.FindInvoicesForCustomer(g.GroupId)
}

func (g *GroupRequest) CancelSubscription() (interface{}, error) {
	return nil, cancelSubscription(g.GroupId)
}

//----------------------------------------------------------
// GroupUpdateCreditCard
//----------------------------------------------------------

type GroupUpdateCreditCardRequest struct {
	GroupId string
	UpdateCreditCardRequest
}

func (g *GroupUpdateCreditCardRequest) Do() (interface{}, error) {
	switch g.Provider {
	case "stripe":
		err := stripe.UpdateCreditCard(g.GroupId, g.Token)
		if err != nil {
			Log.Error("Updating cc for group: %s failed. %s", g.GroupId, err)
		}

		return nil, err
	case "paypal":
		return nil, ErrProviderNotImplemented
	default:
		return nil, ErrProviderNotFound
	}
}
