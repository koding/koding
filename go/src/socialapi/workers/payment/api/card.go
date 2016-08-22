package api

import (
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

	return response.HandleResultAndError(
		payment.DeleteCreditCardForGroup(context.GroupName),
	)
}
