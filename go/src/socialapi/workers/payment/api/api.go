package api

import (
	"net/http"
	"net/url"

	"socialapi/workers/common/response"
	"socialapi/workers/payment"
)

func Subscribe(u *url.URL, h http.Header, req *payment.SubscribeRequest) (int, http.Header, interface{}, error) {
	return response.HandleResultAndClientError(
		req.Do(),
	)
}

func SubscriptionRequest(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	subscriptionRequest := &payment.SubscriptionRequest{
		AccountId: u.Query().Get("account_id"),
	}

	return response.HandleResultAndClientError(
		subscriptionRequest.DoWithDefault(),
	)
}

func InvoiceRequest(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	invoiceRequest := &payment.InvoiceRequest{
		AccountId: u.Query().Get("accountId"),
	}

	return response.HandleResultAndClientError(
		invoiceRequest.Do(),
	)
}

func CreditCardRequest(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	creditCardRequest := &payment.CreditCardRequest{
		AccountId: u.Query().Get("accountId"),
	}

	return response.HandleResultAndClientError(
		creditCardRequest.Do(),
	)
}

func UpdateCreditCardRequest(u *url.URL, h http.Header, req *payment.UpdateCreditCardRequest) (int, http.Header, interface{}, error) {
	return response.HandleResultAndClientError(
		req.Do(),
	)
}

func StripeWebhook(u *url.URL, h http.Header, req *payment.StripeWebhook) (int, http.Header, interface{}, error) {
	return response.HandleResultAndClientError(
		req.Do(),
	)
}
