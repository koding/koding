package api

import (
	"math"
	"net/http"
	"net/url"
	"socialapi/request"
	// TODO delete these socialapi dependencies

	apimodels "socialapi/models"
	"socialapi/workers/common/response"
	"socialapi/workers/notification/models"

	// "github.com/koding/bongo"
)

var NOTIFICATION_LIMIT = 8

func List(u *url.URL, h http.Header, _ interface{}, context *apimodels.Context) (int, http.Header, interface{}, error) {
	// only logged in users can create a channel
	if !context.IsLoggedIn() {
		return response.NewBadRequest(apimodels.ErrNotLoggedIn)
	}

	q := request.GetQuery(u)
	q.GroupName = context.GroupName

	// update the limit if it is needed
	q.Limit = int(math.Min(float64(q.Limit), float64(NOTIFICATION_LIMIT)))

	return response.HandleResultAndError(
		models.NewNotification().List(q),
	)
}

func Glance(u *url.URL, h http.Header, req *models.Notification, context *apimodels.Context) (int, http.Header, interface{}, error) {
	// only logged in users can create a channel
	if !context.IsLoggedIn() {
		return response.NewBadRequest(apimodels.ErrNotLoggedIn)
	}

	q := request.GetQuery(u)
	q.GroupName = context.GroupName
	q.AccountId = context.Client.Account.Id

	if err := req.Glance(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewDefaultOK()
}
