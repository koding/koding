package channel

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/api/modules/helpers"
	"strconv"

	"github.com/jinzhu/gorm"
)

func Create(u *url.URL, h http.Header, req *models.Channel) (int, http.Header, interface{}, error) {
	if err := req.Save(); err != nil {
		return helpers.NewBadRequestResponse()
	}

	return helpers.NewOKResponse(req)
}

func Delete(u *url.URL, h http.Header, req *models.Channel) (int, http.Header, interface{}, error) {
	id, err := strconv.ParseInt(u.Query().Get("id"), 10, 64)
	if err != nil {
		return helpers.NewBadRequestResponse()
	}

	req.Id = id

	if err := req.Delete(); err != nil {
		return helpers.NewBadRequestResponse()
	}
	// yes it is deleted but not removed completely from our system
	return helpers.NewDeletedResponse()
}

func Update(u *url.URL, h http.Header, req *models.Channel) (int, http.Header, interface{}, error) {
	id, err := strconv.ParseInt(u.Query().Get("id"), 10, 64)
	if err != nil {
		return helpers.NewBadRequestResponse()
	}
	req.Id = id

	if req.Id == 0 {
		return helpers.NewBadRequestResponse()
	}

	if err := req.Save(); err != nil {
		return helpers.NewBadRequestResponse()
	}

	return helpers.NewOKResponse(req)
}

func Get(u *url.URL, h http.Header, req *models.Channel) (int, http.Header, interface{}, error) {
	id, err := strconv.ParseInt(u.Query().Get("id"), 10, 64)
	if err != nil {
		return helpers.NewBadRequestResponse()
	}

	req.Id = id
	if err := req.Fetch(); err != nil {
		if err == gorm.RecordNotFound {
			return helpers.NewNotFoundResponse()
		}
		return helpers.NewBadRequestResponse()
	}

	return helpers.NewOKResponse(req)
}
