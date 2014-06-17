package api

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/common/response"
)

func Mark(u *url.URL, h http.Header, req map[string]interface{}) (int, http.Header, interface{}, error) {
	targetId, err := response.GetURIInt64(u, "accountId")
	if err != nil {
		return response.NewBadRequest(err)
	}

	a := models.NewAccount()
	a.Id = targetId

	return response.HandleResultAndError(a, a.MarkAsTroll())
}

func UnMark(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	targetId, err := response.GetURIInt64(u, "accountId")
	if err != nil {
		return response.NewBadRequest(err)
	}

	a := models.NewAccount()
	a.Id = targetId

	return response.HandleResultAndError(a, a.UnMarkAsTroll())
}
