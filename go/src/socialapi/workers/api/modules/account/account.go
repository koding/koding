package account

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/api/modules/helpers"
)

func ListChannels(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	query := helpers.GetQuery(u)

	accountId, err := helpers.GetURIInt64(u, "id")
	if err != nil {
		return helpers.NewBadRequestResponse()
	}

	a := &models.Account{Id: accountId}
	channels, err := a.FetchChannels(query)
	if err != nil {
		return helpers.NewBadRequestResponse()
	}

	return helpers.NewOKResponse(channels)
}
