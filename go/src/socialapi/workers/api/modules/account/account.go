package account

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/common/response"

	"github.com/koding/bongo"
)

// lists followed channels of an account
func ListChannels(u *url.URL, h http.Header, _ interface{}, c *models.Context) (int, http.Header, interface{}, error) {
	query := response.GetQuery(u)

	accountId, err := response.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequestResponse(err)
	}

	if query.Type == "" {
		query.Type = models.Channel_TYPE_TOPIC
	}

	a := &models.Account{Id: accountId}
	channels, err := a.FetchChannels(query)
	if err != nil {
		return response.NewBadRequestResponse(err)
	}

	return response.HandleResultAndError(
		models.PopulateChannelContainersWithUnreadCount(channels, accountId),
	)
}

func ListPosts(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	query := response.GetQuery(u)
	buildMessageQuery := query

	accountId, err := response.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequestResponse(err)
	}

	// Get Group Channel
	selector := map[string]interface{}{
		"group_name":    query.GroupName,
		"type_constant": models.Channel_TYPE_GROUP,
	}

	c := models.NewChannel()
	if err := c.One(bongo.NewQS(selector)); err != nil {
		return response.NewBadRequestResponse(err)
	}
	// fetch only channel messages
	query.Type = models.ChannelMessage_TYPE_POST
	query.AccountId = accountId
	cm := models.NewChannelMessage()
	messages, err := cm.FetchMessagesByChannelId(c.Id, query)
	if err != nil {
		return response.NewBadRequestResponse(err)
	}

	buildMessageQuery.Limit = 3
	return response.HandleResultAndError(
		cm.BuildMessages(buildMessageQuery, messages),
	)
}

func Follow(u *url.URL, h http.Header, req *models.Account) (int, http.Header, interface{}, error) {
	targetId, err := response.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequestResponse(err)
	}

	return response.HandleResultAndError(
		req.Follow(targetId),
	)
}

func Register(u *url.URL, h http.Header, req *models.Account) (int, http.Header, interface{}, error) {

	if err := req.FetchOrCreate(); err != nil {
		return response.NewBadRequestResponse(err)
	}

	return response.NewOKResponse(req)
}

func Unfollow(u *url.URL, h http.Header, req *models.Account) (int, http.Header, interface{}, error) {
	targetId, err := response.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequestResponse(err)
	}

	return response.HandleResultAndError(req.Unfollow(targetId))
}
