package api

import (
	"koding/db/mongodb/modelhelper"
	"net/http"
	"net/url"

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
