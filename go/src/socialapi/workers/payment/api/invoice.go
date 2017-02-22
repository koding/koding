package api

import (
	"net/http"
	"net/url"
	"strconv"

	"socialapi/models"
	"socialapi/workers/common/response"
	"socialapi/workers/payment"
)

// ListInvoice lists invoices of group
func ListInvoice(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if err := context.CanManage(); err != nil {
		return response.NewBadRequest(err)
	}

	urlQuery := u.Query()
	limit, _ := strconv.Atoi(urlQuery.Get("limit"))
	if limit == 0 {
		limit = 10
	}

	return response.HandleResultAndError(
		payment.ListInvoicesForGroup(
			context.GroupName,
			urlQuery.Get("startingAfter"),
			limit,
		),
	)
}
