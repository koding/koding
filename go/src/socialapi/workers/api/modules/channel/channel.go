package channel

import (
	"errors"
	"fmt"
	"koding/db/mongodb/modelhelper"
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

func Create(u *url.URL, h http.Header, req *models.Channel, context *models.Context) (int, http.Header, interface{}, error) {
	// only logged in users can create a channel
	if !context.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	// get group name from context
	req.GroupName = context.GroupName
	req.CreatorId = context.Client.Account.Id

	if req.PrivacyConstant == "" {
		req.PrivacyConstant = models.Channel_PRIVACY_PRIVATE

		// if group is koding, then make it public, because it was public before
		if req.GroupName == models.Channel_KODING_NAME {
			req.PrivacyConstant = models.Channel_PRIVACY_PUBLIC
		}
	}

	if req.TypeConstant == "" {
		return response.NewBadRequest(models.ErrChannelTypeConstantRequired)
	}

	if err := validateChannelRequest(req); err != nil {
		return response.NewBadRequest(err)
	}

	if err := req.Create(); err != nil {
		return response.NewBadRequest(err)
	}

	if _, err := req.AddParticipant(req.CreatorId); err != nil {
		// channel create works as idempotent, that channel might have been created before
		if err != models.ErrAccountIsAlreadyInTheChannel {
			return response.NewBadRequest(err)
		}
	}

	cc := models.NewChannelContainer()
	if err := cc.PopulateWith(*req, context.Client.Account.Id); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(cc)
}

func handleChannelListResponse(channelList []models.Channel, q *request.Query) (int, http.Header, interface{}, error) {
	cc := models.NewChannelContainers()
	if err := cc.Fetch(channelList, q); err != nil {
		return response.NewBadRequest(err)
	}
	cc.AddIsParticipant(q.AccountId)

	return response.HandleResultAndError(cc, cc.Err())
}

func Get(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	id, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	q := request.GetQuery(u)
	q = context.OverrideQuery(q)

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
		cp := models.NewChannelParticipant()
		cp.ChannelId = c.Id
		isInvited, err := cp.IsInvited(q.AccountId)
		if err != nil {
			return response.NewBadRequest(err)
		}

		if !isInvited {
			return response.NewAccessDenied(
				fmt.Errorf(
					"account (%d) tried to retrieve the unattended channel (%d)",
					q.AccountId,
					c.Id,
				),
			)
		}
	}

	cc := models.NewChannelContainer()

	if err := cc.Fetch(c.GetId(), q); err != nil {
		return response.NewBadRequest(err)
	}

	cc.AddIsParticipant(q.AccountId)
	return response.HandleResultAndError(cc, cc.Err)
}

func CheckParticipation(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	q := context.OverrideQuery(request.GetQuery(u))
	if context.Client != nil && context.Client.Account != nil {
		q.AccountId = context.Client.Account.Id
	}

	if q.Type == "" || q.AccountId == 0 {
		return response.NewBadRequest(errors.New("type or accountid is not set"))
	}

	channel, err := models.NewChannel().ByName(q)
	if err != nil {
		return response.NewBadRequest(err)
	}

	res := models.NewCheckParticipationResponse()
	res.Channel = &channel
	res.Account = context.Client.Account
	if context.Client.Account != nil {
		res.AccountToken = context.Client.Account.Token
	}

	canOpen, err := channel.CanOpen(q.AccountId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if !canOpen {
		cp := models.NewChannelParticipant()
		cp.ChannelId = channel.Id
		isInvited, err := cp.IsInvited(q.AccountId)
		if err != nil {
			return response.NewBadRequest(err)
		}

		if !isInvited {
			return response.NewAccessDenied(
				fmt.Errorf(
					"account (%d) tried to retrieve the unattended channel (%d)",
					q.AccountId,
					channel.Id,
				),
			)
		}
	}

	return response.NewOK(res)
}

func Delete(u *url.URL, h http.Header, req *models.Channel, context *models.Context) (int, http.Header, interface{}, error) {
	if !context.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

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

	canOpen, err := req.CanOpen(context.Client.Account.Id)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if !canOpen {
		return response.NewBadRequest(models.ErrCannotOpenChannel)
	}

	// TO-DO
	// add super-admin check here
	if req.CreatorId != context.Client.Account.Id {
		isAdmin, err := modelhelper.IsAdmin(context.Client.Account.Nick, req.GroupName)
		if err != nil {
			return response.NewBadRequest(err)
		}

		if !isAdmin {
			return response.NewAccessDenied(models.ErrAccessDenied)
		}
	}

	if err := req.Delete(); err != nil {
		return response.NewBadRequest(err)
	}
	// yes it is deleted but not removed completely from our system
	return response.NewDeleted()
}

func Update(u *url.URL, h http.Header, req *models.Channel, c *models.Context) (int, http.Header, interface{}, error) {
	if !c.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	id, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}
	req.Id = id

	if req.Id == 0 {
		return response.NewBadRequest(err)
	}

	existingOne, err := models.Cache.Channel.ById(id)
	if err != nil {
		return response.NewBadRequest(err)
	}

	participant, err := existingOne.IsParticipant(c.Client.Account.Id)
	if err != nil {
		return response.NewBadRequest(err)
	}
	if !participant {
		return response.NewBadRequest(models.ErrAccountIsNotParticipant)
	}

	// if user is participant in the channel, then user can update only purpose of the channel
	// other fields cannot be updated by participant or anyone else. Only creator can update
	// purpose and other fields of the channel
	if participant {
		if req.Purpose != "" {
			existingOne.Purpose = req.Purpose
		}
	}

	// if user is the creator of the channel, then can update all fields of the channel
	if existingOne.CreatorId == c.Client.Account.Id {
		if req.Name != "" {
			existingOne.Name = req.Name
		}

		// some of the channels stores sparse data
		existingOne.Payload = req.Payload
	}

	// update channel
	if err := existingOne.Update(); err != nil {
		return response.NewBadRequest(err)
	}

	// generate container data
	cc := models.NewChannelContainer()
	if err := cc.PopulateWith(*existingOne, c.Client.Account.Id); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(cc)
}
