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

func SubscriptionRequest(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	subscriptionRequest := &payment.SubscriptionRequest{
		AccountId: u.Query().Get("accountId"),
	}

	return response.HandleResultAndError(
		subscriptionRequest.Do(),
	)
}

func InvoiceRequest(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	invoiceRequest := &payment.InvoiceRequest{
		AccountId: u.Query().Get("accountId"),
	}

	return response.HandleResultAndError(
		invoiceRequest.Do(),
	)
}

func UpdateCreditCardRequest(u *url.URL, h http.Header, req *payment.UpdateCreditCardRequest) (int, http.Header, interface{}, error) {
	return response.HandleResultAndError(
		req.Do(),
	)
}

func StripeWebhook(u *url.URL, h http.Header, req *payment.StripeWebhook) (int, http.Header, interface{}, error) {
	return response.HandleResultAndError(
		req.Do(),
	)
}
