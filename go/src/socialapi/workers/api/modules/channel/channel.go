package channel

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/api/modules/helpers"

	"github.com/jinzhu/gorm"
)

func Create(u *url.URL, h http.Header, req *models.Channel) (int, http.Header, interface{}, error) {
	if err := req.Create(); err != nil {
		return helpers.NewBadRequestResponse()
	}

	return helpers.NewOKResponse(req)
}

func Delete(u *url.URL, h http.Header, req *models.Channel) (int, http.Header, interface{}, error) {
	id, err := helpers.GetURIInt64(u, "id")
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
	id, err := helpers.GetURIInt64(u, "id")
	if err != nil {
		return helpers.NewBadRequestResponse()
	}
	req.Id = id

	if req.Id == 0 {
		return helpers.NewBadRequestResponse()
	}

	if err := req.Update(); err != nil {
		return helpers.NewBadRequestResponse()
	}

	return helpers.NewOKResponse(req)
}

func Get(u *url.URL, h http.Header, req *models.Channel) (int, http.Header, interface{}, error) {
	id, err := helpers.GetURIInt64(u, "id")
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

func PostMessage(u *url.URL, h http.Header, req *models.Channel) (int, http.Header, interface{}, error) {
	// id, err := helpers.GetURIInt64(u, "id")
	// if err != nil {
	// 	return helpers.NewBadRequestResponse()
	// }

	// req.Id = id
	// // TODO - check if the user is member of the channel

	// if err := req.Fetch(); err != nil {
	// 	if err == gorm.RecordNotFound {
	// 		return helpers.NewNotFoundResponse()
	// 	}
	// 	return helpers.NewBadRequestResponse()
	// }

	return helpers.NewOKResponse(req)
}
