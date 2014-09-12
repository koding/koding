package payment

import (
	"net/http"
	"net/url"

	"socialapi/workers/common/response"
	"socialapi/workers/payment"
)

func CreateSubscription(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	return response.HandleResultAndError(
		payment.CreateSubscription(),
	)
}
