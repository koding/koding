package messagelist

import (
	"errors"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/response"
)

func List(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	channelId, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	cml := models.NewChannelMessageList()
	cml.ChannelId = channelId

	return response.HandleResultAndError(
		cml.List(
			request.GetQuery(u),
			false,
		),
	)
}

func Count(u *url.URL, h http.Header, ml *models.ChannelMessageList) (int, http.Header, interface{}, error) {
	if ml.ChannelId == 0 {
		return response.NewBadRequest(errors.New("channel id is not set"))
	}

	count, err := models.NewChannelMessageList().Count(ml.ChannelId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	res := new(models.CountResponse)
	res.TotalCount = count

	return response.NewOK(res)
}
