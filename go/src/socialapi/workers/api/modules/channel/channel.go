package channel

import (
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/response"

	"github.com/koding/bongo"
)

func validateChannelRequest(c *models.Channel) error {
	if c.GroupName == "" {
		return models.ErrGroupNameIsNotSet
	}

	if c.Name == "" {
		return models.ErrNameIsNotSet
	}

	if c.CreatorId == 0 {
		return models.ErrCreatorIdIsNotSet
	}

	return nil
}

func Create(u *url.URL, h http.Header, req *models.Channel) (int, http.Header, interface{}, error) {
	if req.GroupName == "" {
		req.GroupName = models.Channel_KODING_NAME
	}

	if req.PrivacyConstant == "" {
		req.PrivacyConstant = models.Channel_PRIVACY_PUBLIC
	}

	if err := validateChannelRequest(req); err != nil {
		return response.NewBadRequest(err)
	}

	if err := req.Create(); err != nil {
		return response.NewBadRequest(err)
	}

	if _, err := req.AddParticipant(req.CreatorId); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(req)
}

// List lists only topic channels
func List(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	c := models.NewChannel()
	q := request.GetQuery(u)
	q.Type = models.Channel_TYPE_TOPIC
	// TODO refactor this function just to return channel ids
	// we cache wisely
	channelList, err := c.List(q)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return handleChannelListResponse(channelList, q)
}

func handleChannelListResponse(channelList []models.Channel, q *request.Query) (int, http.Header, interface{}, error) {
	cc := models.NewChannelContainers()
	if err := cc.Fetch(channelList, q); err != nil {
		return response.NewBadRequest(err)
	}
	cc.AddIsParticipant(q.AccountId)

	// TODO this should be in the channel cache by default
	cc.AddLastMessage()

	return response.HandleResultAndError(cc, cc.Err())
}

// Search searchs database against given channel name
// but only returns topic channels
func Search(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	q := request.GetQuery(u)
	q.Type = models.Channel_TYPE_TOPIC

	channelList, err := models.NewChannel().Search(q)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return handleChannelListResponse(channelList, q)
}

// ByName finds topics by their name
func ByName(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	q := request.GetQuery(u)
	q.Type = models.Channel_TYPE_TOPIC

	channel, err := models.NewChannel().ByName(q)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return handleChannelResponse(channel, q)
}

func Get(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	id, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}
	q := request.GetQuery(u)

	c := models.NewChannel()
	if err := c.ById(id); err != nil {
		if err == bongo.RecordNotFound {
			return response.NewNotFound()
		}
		return response.NewBadRequest(err)
	}

	return handleChannelResponse(*c, q)
}

func handleChannelResponse(c models.Channel, q *request.Query) (int, http.Header, interface{}, error) {
	// add troll mode filter
	if c.MetaBits.Is(models.Troll) && !q.ShowExempt {
		return response.NewNotFound()
	}

	canOpen, err := c.CanOpen(q.AccountId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if !canOpen {
		return response.NewAccessDenied(
			fmt.Errorf(
				"account (%d) tried to retrieve the unattended channel (%d)",
				q.AccountId,
				c.Id,
			),
		)
	}

	cc := models.NewChannelContainer()

	if err := cc.Fetch(c.GetId(), q); err != nil {
		return response.NewBadRequest(err)
	}

	cc.AddIsParticipant(q.AccountId)

	// TODO this should be in the channel cache by default
	cc.AddLastMessage()

	return response.HandleResultAndError(cc, cc.Err)
}

func CheckParticipation(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	q := request.GetQuery(u)
	if q.Type == "" || q.AccountId == 0 {
		return response.NewBadRequest(errors.New("type or accountid is not set"))
	}

	channel, err := models.NewChannel().ByName(q)
	if err != nil {
		return response.NewBadRequest(err)
	}

	canOpen, err := channel.CanOpen(q.AccountId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if !canOpen {
		return response.NewAccessDenied(
			fmt.Errorf(
				"account (%d) tried to retrieve the unattended private channel (%d)",
				q.AccountId,
				channel.Id,
			))
	}

	return response.NewOK(channel)
}

func Delete(u *url.URL, h http.Header, req *models.Channel) (int, http.Header, interface{}, error) {

	id, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	if err := req.ById(id); err != nil {
		return response.NewBadRequest(err)
	}

	if req.TypeConstant == models.Channel_TYPE_GROUP {
		return response.NewBadRequest(errors.New("You can not delete group channel"))
	}
	if err := req.Delete(); err != nil {
		return response.NewBadRequest(err)
	}
	// yes it is deleted but not removed completely from our system
	return response.NewDeleted()
}

func Update(u *url.URL, h http.Header, req *models.Channel) (int, http.Header, interface{}, error) {
	id, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}
	req.Id = id

	if req.Id == 0 {
		return response.NewBadRequest(err)
	}

	existingOne, err := models.ChannelById(id)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if existingOne.CreatorId != req.CreatorId {
		return response.NewBadRequest(errors.New("creatorId doesnt match"))
	}

	// only allow purpose and name to be updated
	if req.Purpose != "" {
		existingOne.Purpose = req.Purpose
	}

	if req.Name != "" {
		existingOne.Name = req.Name
	}

	if err := req.Update(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(req)
}
