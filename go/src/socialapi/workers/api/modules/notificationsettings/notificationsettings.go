package notificationsettings

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/response"
)

// Create creates the notification settings with the channelId and accountId
func Create(u *url.URL, h http.Header, req *models.NotificationSettings, ctx *models.Context) (int, http.Header, interface{}, error) {
	if !ctx.IsLoggedIn() {
		return response.NewInvalidRequest(models.ErrNotLoggedIn)
	}

	channelId, err := fetchChannelId(u, c)
	if err != nil {
		return response.NewBadRequest(err)
	}

	req.AccountId = ctx.Client.Account.Id
	req.ChannelId = channelId
	// it looks like we need to add groupName into notification settings structure

	if err := req.Create(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(response.NewSuccessResponse(req))
}

func fetchChannelId(u *url.URL, context *models.Context) (int64, error) {
	channelId, err := request.GetURIInt64(u, "id")
	if err != nil {
		return 0, err
	}

	c, err := models.Cache.Channel.ById(channelId)
	if err != nil {
		return 0, err
	}

	canOpen, err := c.CanOpen(context.Client.Account.Id)
	if err != nil {
		return 0, err
	}

	if !canOpen {
		return 0, models.ErrCannotOpenChannel
	}

	return c.Id, nil
}
