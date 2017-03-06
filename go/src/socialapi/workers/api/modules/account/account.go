package account

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/response"
	"strconv"

	"github.com/koding/bongo"
)

func GetAccountFromSession(u *url.URL, h http.Header, _ interface{}, c *models.Context) (int, http.Header, interface{}, error) {
	if c.Client == nil || c.Client.Account == nil {
		return response.NewNotFound()
	}

	res := map[string]interface{}{
		"id":    strconv.FormatInt(c.Client.Account.Id, 10),
		"nick":  c.Client.Account.Nick,
		"token": c.Client.Account.Token,
	}
	return response.NewOK(res)
}

func Register(u *url.URL, h http.Header, req *models.Account) (int, http.Header, interface{}, error) {

	if err := req.FetchOrCreate(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(req)
}

// Update modifies account data to the lates version by default all requests
// coming to this handler are trusted & validity of the parameters are not
// checked.
//
func Update(u *url.URL, h http.Header, req *models.Account) (int, http.Header, interface{}, error) {
	accountId, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	if accountId == 0 {
		return response.NewBadRequest(models.ErrAccountIdIsNotSet)
	}

	acc := models.NewAccount()
	if err := acc.ById(accountId); err != nil {
		return response.NewBadRequest(err)
	}

	acc.Nick = req.Nick

	if err := models.ValidateAccount(acc); err != nil {
		if err != models.ErrGuestsAreNotAllowed {
			return response.NewBadRequest(err)
		}
	}

	acc.Settings = req.Settings

	if err := acc.Update(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(acc)
}

func CheckOwnership(u *url.URL, h http.Header) (int, http.Header, interface{}, error) {
	accountId, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	query := request.GetQuery(u)

	ownershipResponse := func(err error) (int, http.Header, interface{}, error) {
		var success bool
		switch err {
		case bongo.RecordNotFound:
			success = false
		case nil:
			success = true
		default:
			return response.NewBadRequest(err)
		}
		return response.NewOK(map[string]bool{"success": success})
	}

	switch query.Type {
	case "channel":
		channel := models.NewChannel()
		err = channel.One(&bongo.Query{
			Selector: map[string]interface{}{
				"id":         query.ObjectId,
				"creator_id": accountId,
			},
		})
	}
	return ownershipResponse(err)
}

func ListGroupChannels(u *url.URL, h http.Header, _ interface{}, c *models.Context) (int, http.Header, interface{}, error) {
	if !c.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	cp := models.NewChannelParticipant()
	cids, err := cp.FetchAllParticipatedChannelIdsInGroup(c.Client.Account.Id, c.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	channels, err := models.NewChannel().FetchByIds(cids)
	if err != nil {
		return response.NewBadRequest(err)
	}

	cc := models.NewChannelContainers()
	cc.PopulateWith(channels, c.Client.Account.Id)

	return response.HandleResultAndError(cc, cc.Err())
}
