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
	subscriptionRequest := &payment.AccountRequest{
		AccountId: u.Query().Get("account_id"),
	}

	return response.HandleResultAndClientError(
		subscriptionRequest.DoWithDefault(),
	)
}

func DeleteCustomerRequest(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	req := &payment.AccountRequest{
		AccountId: u.Query().Get("account_id"),
	}

	return response.HandleResultAndClientError(
		req.Delete(),
	)
}

func InvoiceRequest(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	req := &payment.AccountRequest{
		AccountId: u.Query().Get("accountId"),
	}

	return response.HandleResultAndClientError(
		req.Invoices(),
	)
}

func CreditCardRequest(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	req := &payment.AccountRequest{
		AccountId: u.Query().Get("accountId"),
	}

	return response.HandleResultAndClientError(
		req.CreditCard(),
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
