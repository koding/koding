package api

import (
	"errors"
	"koding/db/mongodb/modelhelper"
	"net/http"
	"net/url"

	stripe "github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/charge"

	"socialapi/models"
	"socialapi/workers/common/response"
	"socialapi/workers/payment"
)

// DeleteCreditCard deletes the credit card of a group
func DeleteCreditCard(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if err := checkContext(context); err != nil {
		return response.NewBadRequest(err)
	}

	if err := payment.DeleteCreditCardForGroup(context.GroupName); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewDefaultOK()
}

// HasCreditCard returns the existance status of group's credit card
func HasCreditCard(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if !context.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	group, err := modelhelper.GetGroup(context.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if group.Payment.Customer.ID == "" {
		return response.NewNotFound()
	}

	err = payment.CheckCustomerHasSource(group.Payment.Customer.ID)
	if err == payment.ErrCustomerSourceNotExists {
		return response.NewNotFound()
	}

	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewDefaultOK()
}

// AuthCreditCard auths some many from given source. For more info:
// https://support.stripe.com/questions/does-stripe-support-authorize-and-capture
func AuthCreditCard(u *url.URL, h http.Header, req *stripe.ChargeParams, context *models.Context) (int, http.Header, interface{}, error) {
	if context.Client.SessionID == "" {
		return response.NewBadRequest(errors.New("does not have session id"))
	}

	if context.IsLoggedIn() {
		return response.NewAccessDenied(errors.New("logged out users only"))
	}

	if req.Email == "" {
		return http.StatusBadRequest, nil, nil, errors.New("email is not set")
	}

	chargeParams := &stripe.ChargeParams{
		Amount:   50, // fifty cent
		Currency: "usd",
		Desc:     "AUTH FOR KODING REGISTRATION",
		Source:   req.Source,
		Email:    req.Email,
		// this will help us with validating the request.
		NoCapture: true,
	}
	return response.HandleResultAndClientError(charge.New(chargeParams))
}
