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

	if err != nil {
		Log.Error(
			"Subscribing group: %s to plan: %s failed. %s",
			g.GroupId, g.PlanTitle, err,
		)
	}

	return nil, err
}

//----------------------------------------------------------
// GroupSubscriptions
//----------------------------------------------------------

type GroupRequest struct {
	GroupId string
}

type GroupSubscriptionResponse struct {
	GroupId string
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
