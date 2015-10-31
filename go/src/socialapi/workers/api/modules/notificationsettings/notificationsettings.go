package notificationsettings

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/response"

	"github.com/koding/bongo"
)

// Create creates the notification settings with the channelId and accountId
func Create(u *url.URL, h http.Header, req *models.NotificationSettings, ctx *models.Context) (int, http.Header, interface{}, error) {
	if !ctx.IsLoggedIn() {
		return response.NewInvalidRequest(models.ErrNotLoggedIn)
	}

	channelId, err := fetchChannelId(u, ctx)
	if err != nil {
		return response.NewBadRequest(err)
	}

	req.AccountId = ctx.Client.Account.Id
	req.ChannelId = channelId
	// it looks like we need to add groupName into notification settings structure

	if err := req.Create(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(req)
}

// Get gets the notification settings with id
func Get(u *url.URL, header http.Header, _ interface{}, ctx *models.Context) (int, http.Header, interface{}, error) {
	if !ctx.IsLoggedIn() {
		return response.NewInvalidRequest(models.ErrNotLoggedIn)
	}

	id, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	n := models.NewNotificationSettings()
	err = n.One(&bongo.Query{
		Selector: map[string]interface{}{
			"channel_id": id,
			"account_id": ctx.Client.Account.Id,
		}},
	)
	if err == bongo.RecordNotFound {
		return response.NewNotFound()
	}

	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(n)
}

func Update(u *url.URL, h http.Header, req *models.NotificationSettings, ctx *models.Context) (int, http.Header, interface{}, error) {
	id, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	if !ctx.IsLoggedIn() {
		return response.NewInvalidRequest(models.ErrNotLoggedIn)
	}

	desktopSetting := req.DesktopSetting
	mobileSetting := req.MobileSetting
	isMuted := req.IsMuted
	isSuppressed := req.IsSuppressed

	if err := req.ById(id); err != nil {
		if err == bongo.RecordNotFound {
			return response.NewNotFound()
		}
		return response.NewBadRequest(err)
	}

	if req.Id == 0 {
		return response.NewBadRequest(err)
	}

	req.DesktopSetting = desktopSetting
	req.MobileSetting = mobileSetting
	req.IsMuted = isMuted
	req.IsSuppressed = isSuppressed

	if err := req.Update(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(req)
}

func Delete(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	id, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	ns := models.NewNotificationSettings()
	ns.Id = id

	if err := ns.ById(id); err != nil {
		if err == bongo.RecordNotFound {
			return response.NewNotFound()
		}
		return response.NewBadRequest(err)
	}

	if err := ns.Delete(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewDeleted()
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
