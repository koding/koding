package payment

import (
	"net/http"
	"net/url"

	"socialapi/workers/common/response"
	"socialapi/workers/payment"
)

func Subscribe(u *url.URL, h http.Header, req *payment.SubscriptionRequest) (int, http.Header, interface{}, error) {
	return response.HandleResultAndError(
		req.Subscribe(),
	)
}
