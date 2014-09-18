package account

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/response"

	"github.com/koding/bongo"
)

// lists followed channels of an account
func ListChannels(u *url.URL, h http.Header, _ interface{}, c *models.Context) (int, http.Header, interface{}, error) {
	query := request.GetQuery(u)

	accountId, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
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
		return ownershipResponse(err)
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
