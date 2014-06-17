package activity

import (
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/common/request"
	"socialapi/workers/common/response"
	"time"

	"github.com/koding/bongo"
)

func GetPinnedActivityChannel(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	query := request.GetQuery(u)

	if query.AccountId == 0 {
		return response.NewBadRequest(fmt.Errorf("Account id is not set for fetching pinned activity channel"))
	}

	return response.HandleResultAndError(
		ensurePinnedActivityChannel(
			query.AccountId,
			query.GroupName,
		),
	)
}

func checkPinMessagePrerequisites(channel *models.Channel, pinRequest *models.PinRequest) error {
	if channel.TypeConstant != models.Channel_TYPE_PINNED_ACTIVITY {
		return errors.New("You can not add pinned message into this channel")
	}

	if channel.GroupName != pinRequest.GroupName {
		return errors.New("Grop name and channel group name doesnt match")
	}

	if channel.CreatorId != pinRequest.AccountId {
		return errors.New("Only owner can add new pinned message into this channel")
	}

	return nil
}

func PinMessage(u *url.URL, h http.Header, req *models.PinRequest) (int, http.Header, interface{}, error) {
	if err := validatePinRequest(req); err != nil {
		return response.NewBadRequest(err)
	}

	c, err := ensurePinnedActivityChannel(req.AccountId, req.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if err := checkPinMessagePrerequisites(c, req); err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(c.AddMessage(req.MessageId))
}

func List(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	query := request.GetQuery(u)

	if query.AccountId == 0 {
		return response.NewBadRequest(errors.New("Account id is not set for fetching pinned activities"))
	}

	c, err := ensurePinnedActivityChannel(query.AccountId, query.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if c.CreatorId != query.AccountId {
		return response.NewBadRequest(errors.New("Only owner can list pinned messages"))
	}

	cml := models.NewChannelMessageList()
	cml.ChannelId = c.Id
	return response.HandleResultAndError(cml.List(query, true))
}

func UnpinMessage(u *url.URL, h http.Header, req *models.PinRequest) (int, http.Header, interface{}, error) {
	if err := validatePinRequest(req); err != nil {
		return response.NewBadRequest(err)
	}

	c, err := ensurePinnedActivityChannel(req.AccountId, req.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if err := checkPinMessagePrerequisites(c, req); err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(
		c.RemoveMessage(req.MessageId),
	)
}

func Glance(u *url.URL, h http.Header, req *models.PinRequest) (int, http.Header, interface{}, error) {
	if err := validatePinRequest(req); err != nil {
		return response.NewBadRequest(err)
	}

	c, err := ensurePinnedActivityChannel(req.AccountId, req.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if err := checkPinMessagePrerequisites(c, req); err != nil {
		return response.NewBadRequest(err)
	}

	cml, err := c.FetchMessageList(req.MessageId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	cml.AddedAt = time.Now().UTC()
	if err := cml.Update(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(cml)
}

func validatePinRequest(req *models.PinRequest) error {
	if req.MessageId == 0 {
		return errors.New("Message id is not set")
	}

	if req.AccountId == 0 {
		return errors.New("Account id is not set")
	}

	if req.GroupName == "" {
		return errors.New("Group name is not set")
	}

	return nil
}

func ensurePinnedActivityChannel(accountId int64, groupName string) (*models.Channel, error) {
	c := models.NewChannel()
	query := &bongo.Query{
		Selector: map[string]interface{}{
			"creator_id":    accountId,
			"group_name":    groupName,
			"type_constant": models.Channel_TYPE_PINNED_ACTIVITY,
		},
		Pagination: *bongo.NewPagination(1, 0),
	}

	if err := c.Some(c, query); err != nil {
		return nil, err
	}

	// if we find the channel
	// return early
	if c.Id != 0 {
		return c, nil
	}

	c.Name = models.RandomName()
	c.CreatorId = accountId
	c.GroupName = groupName
	c.TypeConstant = models.Channel_TYPE_PINNED_ACTIVITY
	c.PrivacyConstant = models.Channel_PRIVACY_PRIVATE
	if err := c.Create(); err != nil {
		return nil, err
	}

	// after creating pinned channel
	// add user a participant
	// todo add test for this case
	_, err := c.AddParticipant(accountId)
	if err != nil {
		return nil, err
	}

	return c, nil
}
