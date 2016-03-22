package api

import (
	"net/http"
	"net/url"

	"socialapi/workers/common/response"
	"socialapi/workers/payment"
)

func InitCheckers() error {
	err := payment.InitCheckers()
	return err
}

//----------------------------------------------------------
// Subscribe
//----------------------------------------------------------

func AccountSubscribe(u *url.URL, h http.Header, req *payment.AccountSubscribeRequest) (int, http.Header, interface{}, error) {
	return response.HandleResultAndClientError(
		req.Do(),
	)
}

func GroupSubscribe(u *url.URL, h http.Header, req *payment.GroupSubscribeRequest) (int, http.Header, interface{}, error) {
	return response.HandleResultAndClientError(
		req.Do(),
	)
}

func AccountSubscriptionRequest(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	subscriptionRequest := &payment.AccountRequest{
		AccountId: u.Query().Get("account_id"),
	}

	return response.HandleResultAndClientError(
		subscriptionRequest.Subscriptions(),
	)
}

func AccountCancelSubscriptionRequest(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	subscriptionRequest := &payment.AccountRequest{
		AccountId: u.Query().Get("account_id"),
	}

	return response.HandleResultAndClientError(
		subscriptionRequest.CancelSubscription(),
	)
}

func GroupSubscriptionRequest(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	subscriptionRequest := &payment.GroupRequest{
		GroupId: u.Query().Get("group_id"),
	}

	return response.HandleResultAndClientError(
		subscriptionRequest.Subscriptions(),
	)
}

func GetCustomersRequest(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	req := &payment.AccountRequest{}

	return response.HandleResultAndClientError(
		req.ActiveUsernames(),
	)
}

func ExpireCustomerRequest(u *url.URL, h http.Header, req *payment.AccountRequest) (int, http.Header, interface{}, error) {
	req.AccountId = u.Query().Get("accountId")

	return response.HandleResultAndClientError(
		req.Expire(),
	)
}

func DeleteCustomerRequest(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	req := &payment.AccountRequest{
		AccountId: u.Query().Get("accountId"),
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
		req.GetCreditCard(),
	)
}

func AccountUpdateCreditCardRequest(u *url.URL, h http.Header, req *payment.AccountUpdateCreditCardRequest) (int, http.Header, interface{}, error) {
	return response.HandleResultAndClientError(
		req.Do(),
	)
}

func GroupUpdateCreditCardRequest(u *url.URL, h http.Header, req *payment.GroupUpdateCreditCardRequest) (int, http.Header, interface{}, error) {
	return response.HandleResultAndClientError(
		req.Do(),
	)
}

//----------------------------------------------------------
// Paypal
//----------------------------------------------------------

func PaypalGetToken(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	req := &payment.PaypalGetTokenRequest{
		PlanTitle:    u.Query().Get("planTitle"),
		PlanInterval: u.Query().Get("planInterval"),
	}

	return response.HandleResultAndClientError(
		req.Do(),
	)
}

func PaypalSuccess(u *url.URL, h http.Header, req *payment.PaypalRequest) (int, http.Header, interface{}, error) {
	return response.HandleResultAndClientError(
		req.Success(),
	)
}

func PaypalCancel(u *url.URL, h http.Header, req *payment.PaypalRequest) (int, http.Header, interface{}, error) {
	return response.HandleResultAndClientError(
		req.Cancel(),
	)
}
