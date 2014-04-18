package notification

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/api/modules/helpers"
)

func List(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	n := models.NewNotification()
	list, err := n.List(helpers.GetQuery(u))
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	return helpers.NewOKResponse(list)
}

func Glance(u *url.URL, h http.Header, req *models.Notification) (int, http.Header, interface{}, error) {
	if err := req.Glance(); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	req.Glanced = true

	res := map[string]interface{}{
		"Glanced": true,
	}

	return helpers.NewOKResponse(res)
}
