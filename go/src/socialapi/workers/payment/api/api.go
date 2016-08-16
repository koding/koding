package api

import (
	"errors"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"net/http"
	"net/url"

	stripe "github.com/stripe/stripe-go"

	"socialapi/models"
	"socialapi/workers/common/response"
	"socialapi/workers/payment/paymentclient"
)

var (
	ErrCustomerNotSubscribedToAnyPlans = errors.New("user is not subscribed to any plans")
	ErrCustomerNotExists               = errors.New("user is not created for subscription")
)

func DeleteSubscription(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if err := checkContext(context); err != nil {
		return response.NewBadRequest(err)
	}

	group, err := modelhelper.GetGroup(context.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if group.Payment.Subscription.ID == "" {
		return response.NewBadRequest(ErrCustomerNotSubscribedToAnyPlans)
	}

	return response.HandleResultAndError(
		paymentclient.DeleteSubscription(group.Payment.Subscription.ID),
	)
}

func UpdateSubscription(u *url.URL, h http.Header, params *stripe.SubParams, context *models.Context) (int, http.Header, interface{}, error) {
	if err := checkContext(context); err != nil {
		return response.NewBadRequest(err)
	}

	group, err := modelhelper.GetGroup(context.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if group.Payment.Subscription.ID == "" {
		return response.NewBadRequest(ErrCustomerNotSubscribedToAnyPlans)
	}

	return response.HandleResultAndError(
		paymentclient.UpdateSubscription(group.Payment.Subscription.ID, params),
	)
}

func GetSubscription(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if err := checkContext(context); err != nil {
		return response.NewBadRequest(err)
	}

	group, err := modelhelper.GetGroup(context.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if group.Payment.Subscription.ID == "" {
		return response.NewBadRequest(ErrCustomerNotSubscribedToAnyPlans)
	}

	return response.HandleResultAndError(
		paymentclient.GetSubscription(group.Payment.Subscription.ID),
	)
}

func CreateSubscription(u *url.URL, h http.Header, params *stripe.SubParams, context *models.Context) (int, http.Header, interface{}, error) {
	if err := checkContext(context); err != nil {
		return response.NewBadRequest(err)
	}

	// TODO
	// Add idempotency here
	//
	group, err := modelhelper.GetGroup(context.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	sub, err := paymentclient.CreateSubscription(params)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if err := modelhelper.UpdateGroupPartial(
		modelhelper.Selector{"_id": group.Id},
		modelhelper.Selector{
			"$set": modelhelper.Selector{
				"payment.subscription.id":     sub.ID,
				"payment.subscription.status": sub.Status,
			},
		},
	); err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(sub, err)
}

////////////
////////////
////////////
////////////

func DeleteCustomer(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if err := checkContext(context); err != nil {
		return response.NewBadRequest(err)
	}

	group, err := modelhelper.GetGroup(context.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if group.Payment.Customer.ID == "" {
		return response.NewBadRequest(ErrCustomerNotExists)
	}

	if err := paymentclient.DeleteCustomer(group.Payment.Customer.ID); err != nil {
		return response.NewBadRequest(err)
	}

	if err := modelhelper.UpdateGroupPartial(
		modelhelper.Selector{"_id": group.Id},
		modelhelper.Selector{
			"$unset": modelhelper.Selector{"payment.customer.id": ""},
		},
	); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewDeleted()
}

func UpdateCustomer(u *url.URL, h http.Header, params *stripe.CustomerParams, context *models.Context) (int, http.Header, interface{}, error) {
	if err := checkContext(context); err != nil {
		return response.NewBadRequest(err)
	}

	group, err := modelhelper.GetGroup(context.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if group.Payment.Customer.ID == "" {
		return response.NewBadRequest(ErrCustomerNotExists)
	}

	params, err = populateCustomerParams(params, context)
	if err != nil {
		return response.NewBadRequest(err)
	}

	cus, err := paymentclient.UpdateCustomer(group.Payment.Customer.ID, params)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(cus)
}

func GetCustomer(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if err := checkContext(context); err != nil {
		return response.NewBadRequest(err)
	}

	group, err := modelhelper.GetGroup(context.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if group.Payment.Customer.ID == "" {
		return response.NewBadRequest(ErrCustomerNotExists)
	}

	return response.HandleResultAndError(
		paymentclient.GetCustomer(group.Payment.Customer.ID),
	)
}

func CreateCustomer(u *url.URL, h http.Header, req *stripe.CustomerParams, context *models.Context) (int, http.Header, interface{}, error) {
	if err := checkContext(context); err != nil {
		return response.NewBadRequest(err)
	}

	req, err := populateCustomerParams(req, context)
	if err != nil {
		return response.NewBadRequest(err)
	}

	cus, err := paymentclient.CreateCustomer(req)
	if err != nil {
		return response.NewBadRequest(err)
	}

	group, err := modelhelper.GetGroup(context.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if err := modelhelper.UpdateGroupPartial(
		modelhelper.Selector{"_id": group.Id},
		modelhelper.Selector{
			"$set": modelhelper.Selector{
				"payment.customer.id": cus.ID,
			},
		},
	); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(cus)
}

func DeleteCreditCard(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if err := checkContext(context); err != nil {
		return response.NewBadRequest(err)
	}

	group, err := modelhelper.GetGroup(context.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if group.Payment.Customer.ID == "" {
		return response.NewBadRequest(ErrCustomerNotExists)
	}

	return response.HandleResultAndError(paymentclient.DeleteCreditCard(group.Payment.Customer.ID))
}

func populateCustomerParams(req *stripe.CustomerParams, context *models.Context) (*stripe.CustomerParams, error) {
	if req == nil {
		req = &stripe.CustomerParams{}
	}

	user, err := modelhelper.GetUser(context.Client.Account.Nick)
	if err != nil {
		return nil, err
	}

	if req.Desc == "" {
		req.Desc = fmt.Sprintf("%s team", context.GroupName)
	}
	if req.Email == "" {
		req.Email = user.Email
	}

	if req.Params.Meta == nil {
		req.Params.Meta = make(map[string]string)
	}
	req.Params.Meta["groupName"] = context.GroupName
	req.Params.Meta["username"] = context.Client.Account.Nick
	req.Params.Meta["old_id"] = context.Client.Account.OldId

	return req, nil
}

func checkContext(c *models.Context) error {
	if !c.IsLoggedIn() {
		return models.ErrNotLoggedIn
	}

	isAdmin, err := modelhelper.IsAdmin(c.Client.Account.Nick, c.GroupName)
	if err != nil {
		return err
	}

	if !isAdmin {
		return models.ErrAccessDenied
	}

	return nil
}
