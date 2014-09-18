package payment

import (
	"net/http"
	"net/url"

	"socialapi/workers/common/response"
	"socialapi/workers/payment"
)

func Subscribe(u *url.URL, h http.Header, req *payment.SubscribeRequest) (int, http.Header, interface{}, error) {
	return response.HandleResultAndError(
		req.Do(),
	)
}

func SubscriptionRequest(u *url.URL, h http.Header, req *payment.SubscriptionRequest) (int, http.Header, interface{}, error) {
	req.AccountId = u.Query().Get("accountId")

	return response.HandleResultAndError(
		req.Do(),
	)
}

func StripeWebhook(u *url.URL, h http.Header, req *payment.StripeWebhook) (int, http.Header, interface{}, error) {
	return response.HandleResultAndError(
		req.Do(),
	)
}
