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
	id, err := helpers.GetId(u)
	if err != nil {
		return helpers.NewBadRequestResponse()
	}

	if req.AccountId == 0 {
		log.Error("account id is not set")
		return helpers.NewBadRequestResponse()
	}

	req.ChannelId = id
	req.Status = models.ACTIVE

	if err := req.Create(); err != nil {
		return helpers.NewBadRequestResponse()
	}

	return helpers.NewOKResponse(req)
}

func Delete(u *url.URL, h http.Header, req *models.ChannelParticipant) (int, http.Header, interface{}, error) {
	id, err := helpers.GetId(u)
	if err != nil {
		return helpers.NewBadRequestResponse()
	}

	if req.AccountId == 0 {
		log.Error("account id is not set")
		return helpers.NewBadRequestResponse()
	}

	req.ChannelId = id

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
