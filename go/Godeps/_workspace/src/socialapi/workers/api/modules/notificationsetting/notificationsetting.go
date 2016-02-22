package notificationsetting

import (
	"errors"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/response"

	"github.com/cihangir/nisql"
	"github.com/koding/bongo"
)

var (
	ErrTypeAssertion = errors.New("type assertion error")
)

// Create creates the notification settings with the channelId and accountId
func Create(u *url.URL, h http.Header, req *models.NotificationSetting, ctx *models.Context) (int, http.Header, interface{}, error) {
	if !ctx.IsLoggedIn() {
		return response.NewInvalidRequest(models.ErrNotLoggedIn)
	}

	channelId, err := fetchChannelIdwithParticipantCheck(u, ctx)
	if err != nil {
		return response.NewBadRequest(err)
	}

	req.AccountId = ctx.Client.Account.Id
	req.ChannelId = channelId

	if err := req.Create(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(req)
}

// Get gets the notification settings with id
// If any notification setting is not found in DB,
// returns 'Not Found' error , and it means that we'r gonna show default settings
func Get(u *url.URL, header http.Header, _ interface{}, ctx *models.Context) (int, http.Header, interface{}, error) {
	if !ctx.IsLoggedIn() {
		return response.NewInvalidRequest(models.ErrNotLoggedIn)
	}

	id, err := fetchChannelIdwithParticipantCheck(u, ctx)
	if err != nil {
		return response.NewBadRequest(err)
	}

	n := models.NewNotificationSetting()
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

// Update udpates the notification setting
func Update(u *url.URL, h http.Header, a map[string]interface{}, ctx *models.Context) (int, http.Header, interface{}, error) {
	id, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	if !ctx.IsLoggedIn() {
		return response.NewInvalidRequest(models.ErrNotLoggedIn)
	}

	req := models.NewNotificationSetting()

	if err := req.ById(id); err != nil {
		if err == bongo.RecordNotFound {
			return response.NewNotFound()
		}
		return response.NewBadRequest(err)
	}

	if req.Id == 0 {
		return response.NewBadRequest(err)
	}

	// check if notification setting's account is the same with requester account
	if req.AccountId != ctx.Client.Account.Id {
		return response.NewInvalidRequest(models.ErrAccountNotFound)
	}

	// Here we update notification setting with incoming request datas
	// if field have null or any value, then we update the field
	// otherwise we dont change any value of notification setting struct
	req, err = parseToNotificationSetting(a, req)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if err := req.Update(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(req)
}

// Delete deletes the notification setting of the user
func Delete(u *url.URL, h http.Header, _ interface{}, ctx *models.Context) (int, http.Header, interface{}, error) {
	id, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	ns := models.NewNotificationSetting()
	ns.Id = id

	if err := ns.ById(id); err != nil {
		if err == bongo.RecordNotFound {
			return response.NewNotFound()
		}
		return response.NewBadRequest(err)
	}

	if ns.AccountId != ctx.Client.Account.Id {
		return response.NewInvalidRequest(models.ErrAccountNotFound)
	}

	if err := ns.Delete(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewDeleted()
}

// parseToNotificationSetting updates the given notification settings struct
// with given map[string]interface.
// If interface value does exist , then we update notification setting even if interface value is  null
func parseToNotificationSetting(a map[string]interface{}, r *models.NotificationSetting) (*models.NotificationSetting, error) {

	if value, ok := a["desktopSetting"]; ok {
		if value == nil {
			r.DesktopSetting = nisql.NullString{}

		} else {
			data, k := value.(string)
			if k {
				r.DesktopSetting = nisql.String(data)
			} else {
				return nil, ErrTypeAssertion
			}
		}
	}

	if value, ok := a["mobileSetting"]; ok {
		if value == nil {
			r.MobileSetting = nisql.NullString{}

		} else {
			data, k := value.(string)
			if k {
				r.MobileSetting = nisql.String(data)
			} else {
				return nil, ErrTypeAssertion
			}
		}
	}

	if value, ok := a["isSuppressed"]; ok {
		if value == nil {
			r.IsSuppressed = nisql.NullBool{}

		} else {
			data, k := value.(bool)
			if k {
				r.IsSuppressed = nisql.Bool(data)
			} else {
				return nil, ErrTypeAssertion
			}
		}
	}

	if value, ok := a["isMuted"]; ok {
		if value == nil {
			r.IsMuted = nisql.NullBool{}

		} else {
			data, k := value.(bool)
			if k {
				r.IsMuted = nisql.Bool(data)
			} else {
				return nil, ErrTypeAssertion
			}
		}
	}

	return r, nil
}

func fetchChannelIdwithParticipantCheck(u *url.URL, context *models.Context) (int64, error) {
	channelId, err := request.GetURIInt64(u, "id")
	if err != nil {
		return 0, err
	}

	c, err := models.Cache.Channel.ById(channelId)
	if err != nil {
		return 0, err
	}

	isParticipant, err := c.IsParticipant(context.Client.Account.Id)
	if err != nil {
		return 0, err
	}

	if !isParticipant {
		return 0, models.ErrAccountIsNotParticipant
	}

	return c.Id, nil
}
