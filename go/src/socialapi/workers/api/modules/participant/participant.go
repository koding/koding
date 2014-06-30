package participant

import (
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/response"
	"time"
)

func List(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	channelId, err := request.GetURIInt64(u, "id")
	if err != nil {
		fmt.Println(err)
		return response.NewBadRequest(err)
	}

	req := models.NewChannelParticipant()
	req.ChannelId = channelId
	return response.HandleResultAndError(
		req.List(request.GetQuery(u)),
	)
}

// todo fix duplicate code block with Delete handler
func Add(u *url.URL, h http.Header, req *models.ChannelParticipant) (int, http.Header, interface{}, error) {
	// we are getting requester from body for now, but it will be gotten
	// from the token
	requesterId := req.AccountId
	if requesterId == 0 {
		return response.NewBadRequest(errors.New("Requester AccountId is not set"))
	}

	channelId, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	accountId, err := request.GetURIInt64(u, "accountId")
	if err != nil {
		return response.NewBadRequest(err)
	}

	if err := checkChannelPrerequisites(channelId, requesterId, accountId); err != nil {
		return response.NewBadRequest(err)
	}

	// do not forget to override account id
	req.AccountId = accountId
	req.ChannelId = channelId
	req.StatusConstant = models.ChannelParticipant_STATUS_ACTIVE

	if err := req.Create(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(req)
}

func checkChannelPrerequisites(channelId, requesterId, accountId int64) error {
	c := models.NewChannel()
	if err := c.ById(channelId); err != nil {
		return err
	}

	if c.TypeConstant == models.Channel_TYPE_PINNED_ACTIVITY {
		return errors.New("You can not add/remove a new participant for pinned activity channel")
	}

	if c.TypeConstant == models.Channel_TYPE_CHAT {
		if requesterId != c.CreatorId {
			return errors.New("Only owners can add/remove participants to chat channel")
		}
	}
	return nil
}

func Delete(u *url.URL, h http.Header, req *models.ChannelParticipant) (int, http.Header, interface{}, error) {
	// we are getting requester from body for now, but it will be gotten
	// from the token
	requesterId := req.AccountId
	if requesterId == 0 {
		return response.NewBadRequest(errors.New("Requester AccountId is not set"))
	}

	channelId, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	accountId, err := request.GetURIInt64(u, "accountId")
	if err != nil {
		return response.NewBadRequest(err)
	}

	if err := checkChannelPrerequisites(channelId, requesterId, accountId); err != nil {
		return response.NewBadRequest(err)
	}

	// do not forget to override account id
	req.AccountId = accountId
	req.ChannelId = channelId

	if err := req.Delete(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(req)
}

func Presence(u *url.URL, h http.Header, req *models.ChannelParticipant) (int, http.Header, interface{}, error) {
	// we are getting requester from body for now, but it will be gotten
	// from the token
	requesterId := req.AccountId
	if requesterId == 0 {
		return response.NewBadRequest(errors.New("Requester AccountId is not set"))
	}

	channelId, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	accountId, err := request.GetURIInt64(u, "accountId")
	if err != nil {
		return response.NewBadRequest(err)
	}

	// do not forget to override account id
	req.AccountId = accountId
	req.ChannelId = channelId

	if err := req.FetchParticipant(); err != nil {
		return response.NewBadRequest(err)
	}

	req.LastSeenAt = time.Now().UTC()

	if err := req.Update(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(req)
}
