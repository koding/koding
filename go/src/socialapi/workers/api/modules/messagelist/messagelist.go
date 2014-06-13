package messagelist

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/api/modules/helpers"
)

func List(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	channelId, err := helpers.GetURIInt64(u, "id")
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	cml := models.NewChannelMessageList()
	cml.ChannelId = channelId

	return helpers.HandleResultAndError(
		cml.List(
			helpers.GetQuery(u),
			false,
		),
	)
}
