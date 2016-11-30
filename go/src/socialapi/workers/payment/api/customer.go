package api

import (
	"koding/db/mongodb/modelhelper"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/common/response"
	"socialapi/workers/payment"

	stripe "github.com/stripe/stripe-go"
)

// DeleteCustomer deletes customer for a group. Here for symmetry.
func DeleteCustomer(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	// do not allow customer deletion, causes losing track of transactions.
	return http.StatusForbidden, nil, nil, nil

	if err := checkContext(context); err != nil {
		return response.NewBadRequest(err)
	}

	if err := payment.DeleteCustomerForGroup(context.GroupName); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewDeleted()
}

// UpdateCustomer updates customer of a group
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

// GetCustomer returns the customer info of a group
func GetCustomer(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if err := checkContext(context); err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(
		payment.GetCustomerForGroup(context.GroupName),
	)
}

// CreateCustomer creates the customer for a group
func CreateCustomer(u *url.URL, h http.Header, req *stripe.CustomerParams, context *models.Context) (int, http.Header, interface{}, error) {
	if err := checkContext(context); err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(
		payment.EnsureCustomerForGroup(
			context.Client.Account.Nick,
			context.GroupName,
			req,
		),
	)
}

// Info return usage info for a group
func Info(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if err := checkContext(context); err != nil {
		return response.NewBadRequest(err)
	}

	group, err := modelhelper.GetGroup(context.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(
		payment.EnsureInfoForGroup(group, context.Client.Account.Nick),
	)
}
