package messagelist

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/common/response"
)

func List(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	channelId, err := response.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	cml := models.NewChannelMessageList()
	cml.ChannelId = channelId

	return response.HandleResultAndError(
		cml.List(
			response.GetQuery(u),
			false,
		),
	)
}
