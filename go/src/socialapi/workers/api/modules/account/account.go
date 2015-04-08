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

// lists followed channels of an account
func ListChannels(u *url.URL, h http.Header, _ interface{}, c *models.Context) (int, http.Header, interface{}, error) {

	accountId, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	query := request.GetQuery(u)
	if query.AccountId == 0 {
		query.AccountId = accountId
	}

	if query.Type == "" {
		query.Type = models.Channel_TYPE_TOPIC
	}

	a := &models.Account{Id: accountId}
	channels, err := a.FetchChannels(query)
	if err != nil {
		return response.NewBadRequest(err)
	}

	cc := models.NewChannelContainers()
	cc.PopulateWith(channels, query.AccountId).AddUnreadCount(query.AccountId)

	return response.HandleResultAndError(cc, cc.Err())
}

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

func ParticipatedChannelCount(u *url.URL, h http.Header, _ interface{}, c *models.Context) (int, http.Header, interface{}, error) {
	query := request.GetQuery(u)

	accountId, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	if query.Type == "" {
		query.Type = models.Channel_TYPE_TOPIC
	}
	cp := models.NewChannelParticipant()
	a := &models.Account{Id: accountId}

	return response.HandleResultAndError(cp.ParticipatedChannelCount(a, query))
}

func ListPosts(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	query := request.GetQuery(u)
	buildMessageQuery := query.Clone()

	accountId, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	// Get Group Channel
	selector := map[string]interface{}{
		"group_name":    query.GroupName,
		"type_constant": models.Channel_TYPE_GROUP,
	}

	c := models.NewChannel()
	if err := c.One(bongo.NewQS(selector)); err != nil {
		return response.NewBadRequest(err)
	}
	// fetch only channel messages
	query.Type = models.ChannelMessage_TYPE_POST
	query.AccountId = accountId
	cm := models.NewChannelMessage()
	messages, err := cm.FetchMessagesByChannelId(c.Id, query)
	if err != nil {
		return response.NewBadRequest(err)
	}

	buildMessageQuery.Limit = 3
	return response.HandleResultAndError(
		cm.BuildMessages(buildMessageQuery, messages),
	)
}

func FetchPostCount(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	query := request.GetQuery(u)

	accountId, err := request.GetId(u)
	if err != nil {
		return response.NewBadRequest(err)
	}

	// Get Group Channel
	selector := map[string]interface{}{
		"group_name":    query.GroupName,
		"type_constant": models.Channel_TYPE_GROUP,
	}

	// first check channel existence
	c := models.NewChannel()
	if err := c.One(bongo.NewQS(selector)); err != nil {
		return response.NewBadRequest(err)
	}

	// check if user can open the channel
	ok, err := c.CanOpen(accountId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if !ok {
		return response.NewAccessDenied(nil)
	}

	// fetch user post count in koding channel
	q := request.NewQuery()
	q.AccountId = accountId
	q.Type = models.ChannelMessage_TYPE_POST
	q.GroupChannelId = c.Id
	cm := models.NewChannelMessage()

	count, err := cm.FetchTotalMessageCount(q)
	if err != nil {
		return response.NewBadRequest(err)
	}

	res := new(models.CountResponse)
	res.TotalCount = count

	return response.NewOK(res)
}

func Follow(u *url.URL, h http.Header, req *models.Account) (int, http.Header, interface{}, error) {
	targetId, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(
		req.Follow(targetId),
	)
}

func Register(u *url.URL, h http.Header, req *models.Account) (int, http.Header, interface{}, error) {

	if err := req.FetchOrCreate(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(req)
}

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

func Unfollow(u *url.URL, h http.Header, req *models.Account) (int, http.Header, interface{}, error) {
	targetId, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(req.Unfollow(targetId))
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
	case "channel-message":
		channelMessage := models.NewChannelMessage()
		err = channelMessage.One(&bongo.Query{
			Selector: map[string]interface{}{
				"id":         query.ObjectId,
				"account_id": accountId,
			},
		})
	}
	return ownershipResponse(err)
}
