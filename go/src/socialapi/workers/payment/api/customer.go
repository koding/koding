package api

import (
	"errors"
	"koding/db/mongodb/modelhelper"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/common/response"
	"socialapi/workers/payment"

	stripe "github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/customer"
)

// DeleteCustomer deletes customer for a group. Here for symmetry.
func DeleteCustomer(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	// do not allow customer deletion, causes losing track of transactions.
	return http.StatusForbidden, nil, nil, nil

	if err := context.CanManage(); err != nil {
		return response.NewBadRequest(err)
	}

	if err := payment.DeleteCustomerForGroup(context.GroupName); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewDeleted()
}

// UpdateCustomer updates customer of a group
func UpdateCustomer(u *url.URL, h http.Header, params *stripe.CustomerParams, context *models.Context) (int, http.Header, interface{}, error) {
	if err := context.CanManage(); err != nil {
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
	if err := context.CanManage(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(
		payment.GetCustomerForGroup(context.GroupName),
	)
}

// CreateCustomer creates the customer for a group
func CreateCustomer(u *url.URL, h http.Header, req *stripe.CustomerParams, context *models.Context) (int, http.Header, interface{}, error) {
	if err := context.CanManage(); err != nil {
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

// CreateCustomCustomer creates a custom customer for a group
func CreateCustomCustomer(u *url.URL, h http.Header, initial *stripe.CustomerParams) (int, http.Header, interface{}, error) {
	if initial.Email == "" {
		return response.NewBadRequest(errors.New("not set: email"))
	}

	if len(initial.Params.Meta) == 0 {
		return response.NewBadRequest(errors.New("not set: meta"))
	}

	if _, ok := initial.Params.Meta["phone"]; !ok {
		return response.NewBadRequest(errors.New("not set: meta.phone"))
	}

	if initial.Token == "" {
		return response.NewBadRequest(errors.New("not set: token"))
	}

	// whitelisted parameters
	req := &stripe.CustomerParams{
		Token:  initial.Token,
		Coupon: initial.Coupon,
		Source: initial.Source,
		Desc:   initial.Desc,
		Email:  initial.Email,
		Params: initial.Params,
		// plan can not be updated by hand, do not add it to whilelist. It
		// should only be updated automatically on invoice applications
		// Plan: initial.Plan,
	}

	if req.Desc == "" {
		req.Desc = "koding team"
	}

	req.Params.Meta["groupName"] = "koding"
	req.Params.Meta["username"] = "username"

	return response.HandleResultAndError(customer.New(req))
}

// Info return usage info for a group
func Info(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if err := context.CanManage(); err != nil {
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
