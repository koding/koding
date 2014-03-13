package participant

import (
	"fmt"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/api/modules/helpers"

	"github.com/coreos/go-log/log"
	"github.com/jinzhu/gorm"
)

func Add(u *url.URL, h http.Header, req *models.ChannelParticipant) (int, http.Header, interface{}, error) {
	channelId, err := helpers.GetURIInt64(u, "id")
	if err != nil {
		return helpers.NewBadRequestResponse()
	}

	accountId, err := helpers.GetURIInt64(u, "accountId")
	if err != nil {
		return helpers.NewBadRequestResponse()
	}

	req.AccountId = accountId
	req.ChannelId = channelId
	req.Status = models.ChannelParticipant_STATUS_ACTIVE

	if err := req.Create(); err != nil {
		return helpers.NewBadRequestResponse()
	}

	return helpers.NewOKResponse(req)
}

func Delete(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	channelId, err := helpers.GetURIInt64(u, "id")
	if err != nil {
		return helpers.NewBadRequestResponse()
	}

	accountId, err := helpers.GetURIInt64(u, "accountId")
	if err != nil {
		return helpers.NewBadRequestResponse()
	}

	req := models.NewChannelParticipant()
	req.AccountId = accountId
	req.ChannelId = channelId

	if err := req.Delete(); err != nil {
		return helpers.NewBadRequestResponse()
	}

	// yes it is deleted but not removed completely from our system
	return helpers.NewDeletedResponse()
}

func List(u *url.URL, h http.Header, req *models.ChannelParticipant) (int, http.Header, interface{}, error) {
	fmt.Println(u.Query().Get("id"))
	id, err := helpers.GetId(u)
	if err != nil {
		fmt.Println(err)
		return helpers.NewBadRequestResponse()
	}

	req.ChannelId = id
	participants, err := req.List()
	if err != nil {
		if err == gorm.RecordNotFound {
			return helpers.NewNotFoundResponse()
		}
		return helpers.NewBadRequestResponse()
	}

	return helpers.NewOKResponse(participants)
}
