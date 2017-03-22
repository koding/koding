package api

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/common/response"
	"socialapi/workers/payment"
	"socialapi/workers/presence"
	"time"

	"github.com/koding/bongo"
	stripe "github.com/stripe/stripe-go"
)

// CancelSubscription cancels the subscription of group
func CancelSubscription(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if err := context.CanManage(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(
		payment.CancelSubscriptionForGroup(context.GroupName),
	)
}

// GetSubscription gets the subscription of group
func GetSubscription(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if !context.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	return response.HandleResultAndError(
		payment.GetSubscriptionForGroup(context.GroupName),
	)
}

// CreateSubscription creates the subscription of group
func CreateSubscription(u *url.URL, h http.Header, params *stripe.SubParams, context *models.Context) (int, http.Header, interface{}, error) {
	if !context.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	sub, err := payment.EnsureSubscriptionForGroup(context.GroupName, params)
	if err != nil {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	ping := presence.Ping{
		GroupName: context.GroupName,
		AccountID: context.Client.Account.Id,
		CreatedAt: time.Now().UTC(),
	}
	// send the ping request to the related worker
	_ = bongo.B.PublishEvent(presence.EventName, ping) // best effort, nothing vital.

	return response.NewOK(sub)
}
