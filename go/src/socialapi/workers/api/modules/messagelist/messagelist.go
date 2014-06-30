package messagelist

import (
	"errors"
	"fmt"
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

	query := request.GetQuery(u)
	if query.AccountId == 0 {
		return response.NewBadRequest(errors.New("account id is not set"))
	}

	c, err := models.ChannelById(channelId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	// if channel is exempt and
	// user should see the content, return not found err
	if c.MetaBits.Is(models.Troll) && !query.ShowExempt {
		return response.NewNotFound()
	}

	canOpen, err := c.CanOpen(query.AccountId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if !canOpen {
		return response.NewAccessDenied(
			fmt.Errorf(
				"account (%d) tried to retrieve the unattended private channel (%d)",
				query.AccountId,
				c.Id,
			))
	}

	cml := models.NewChannelMessageList()
	cml.ChannelId = c.Id

	return response.HandleResultAndError(
		cml.List(query, false),
	)
}

func Count(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	channelId, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}
	if channelId == 0 {
		return response.NewBadRequest(errors.New("channel id is not set"))
	}

	count, err := models.NewChannelMessageList().Count(channelId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	res := new(models.CountResponse)
	res.TotalCount = count

	return response.NewOK(res)
}
