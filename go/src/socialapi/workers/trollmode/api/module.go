package api

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/api/modules/helpers"
)

func Mark(u *url.URL, h http.Header, req map[string]interface{}) (int, http.Header, interface{}, error) {
	targetId, err := helpers.GetURIInt64(u, "accountId")
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	a := models.NewAccount()
	a.Id = targetId

	return helpers.HandleResultAndError(a, a.MarkAsTroll())
}

func UnMark(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	targetId, err := helpers.GetURIInt64(u, "accountId")
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	a := models.NewAccount()
	a.Id = targetId

	return helpers.HandleResultAndError(a, a.UnMarkAsTroll())
}
