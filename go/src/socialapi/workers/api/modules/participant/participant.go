package participant

import (
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/api/modules/helpers"

	"github.com/jinzhu/gorm"
)

func List(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	channelId, err := helpers.GetURIInt64(u, "id")
	if err != nil {
		fmt.Println(err)
		return helpers.NewBadRequestResponse(err)
	}

	req := models.NewChannelParticipant()
	req.ChannelId = channelId
	participants, err := req.List()
	if err != nil {
		if err == gorm.RecordNotFound {
			return helpers.NewNotFoundResponse()
		}
		return helpers.NewBadRequestResponse(err)
	}

	return helpers.NewOKResponse(participants)
}

// todo fix duplicate code block with Delete handler
func Add(u *url.URL, h http.Header, req *models.ChannelParticipant) (int, http.Header, interface{}, error) {
	// we are getting requester from body for now, but it will be gotten
	// from the token
	requesterId := req.AccountId
	if requesterId == 0 {
		return helpers.NewBadRequestResponse(errors.New("Requester AccountId is not set"))
	}

	channelId, err := helpers.GetURIInt64(u, "id")
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	accountId, err := helpers.GetURIInt64(u, "accountId")
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	if err := checkChannelPrerequisites(channelId, requesterId, accountId); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	// do not forget to override account id
	req.AccountId = accountId
	req.ChannelId = channelId
	req.StatusConstant = models.ChannelParticipant_STATUS_ACTIVE

	if err := req.Create(); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	return helpers.NewOKResponse(req)
}

func checkChannelPrerequisites(channelId, requesterId, accountId int64) error {
	c := models.NewChannel()
	c.Id = channelId
	if err := c.Fetch(); err != nil {
		return err
	}
	if c.TypeConstant == models.Channel_TYPE_PINNED_ACTIVITY {
		return errors.New("You can not add a new participant into pinned activity channel")
	}
	return nil
}

func Delete(u *url.URL, h http.Header, req *models.ChannelParticipant) (int, http.Header, interface{}, error) {
	// we are getting requester from body for now, but it will be gotten
	// from the token
	requesterId := req.AccountId
	if requesterId == 0 {
		return helpers.NewBadRequestResponse(errors.New("Requester AccountId is not set"))
	}

	channelId, err := helpers.GetURIInt64(u, "id")
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	accountId, err := helpers.GetURIInt64(u, "accountId")
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	if err := checkChannelPrerequisites(channelId, requesterId, accountId); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	// do not forget to override account id
	req.AccountId = accountId
	req.ChannelId = channelId

	if err := req.Delete(); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	// yes it is deleted but not removed completely from our system
	return helpers.NewDeletedResponse()
}
