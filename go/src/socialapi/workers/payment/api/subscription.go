package api

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/common/response"
	"socialapi/workers/payment"

	"github.com/stripe/stripe-go"
)

func DeleteSubscription(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if err := checkContext(context); err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(
		payment.DeleteSubscriptionForGroup(context.GroupName),
	)
}

func GetSubscription(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if err := checkContext(context); err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(
		payment.GetSubscriptionForGroup(context.GroupName),
	)
}

func CreateSubscription(u *url.URL, h http.Header, params *stripe.SubParams, context *models.Context) (int, http.Header, interface{}, error) {
	if err := checkContext(context); err != nil {
		return response.NewBadRequest(err)
	}

	// TODO
	// Add idempotency here
	//

	return response.HandleResultAndError(
		payment.CreateSubscriptionForGroup(context.GroupName, params),
	)
}
