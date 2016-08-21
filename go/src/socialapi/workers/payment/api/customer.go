package api

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/common/response"
	"socialapi/workers/payment"

	"github.com/stripe/stripe-go"
)

func DeleteCustomer(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if err := checkContext(context); err != nil {
		return response.NewBadRequest(err)
	}

	if err := payment.DeleteCustomerForGroup(context.GroupName); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewDeleted()
}

func UpdateCustomer(u *url.URL, h http.Header, params *stripe.CustomerParams, context *models.Context) (int, http.Header, interface{}, error) {
	if err := checkContext(context); err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(
		payment.UpdateCustomerForGroup(
			context.Client.Account.Nick,
			context.GroupName,
			params,
		),
	)
}

func GetCustomer(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if err := checkContext(context); err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(
		payment.GetCustomerForGroup(context.GroupName),
	)
}

func CreateCustomer(u *url.URL, h http.Header, req *stripe.CustomerParams, context *models.Context) (int, http.Header, interface{}, error) {
	if err := checkContext(context); err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(
		payment.CreateCustomerForGroup(
			context.Client.Account.Nick,
			context.GroupName,
			req,
		),
	)
}
