package notification

import (
	"github.com/jinzhu/gorm"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/api/modules/helpers"
)

func List(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	n := models.NewNotification()
	list, err := n.List(helpers.GetQuery(u))
	if err != nil {
		if err == gorm.RecordNotFound {
			return helpers.NewNotFoundResponse()
		}

		return helpers.NewBadRequestResponse(err)
	}

	return helpers.NewOKResponse(list)
}

func Glance(u *url.URL, h http.Header, req *models.Notification) (int, http.Header, interface{}, error) {
	if err := req.Glance(); err != nil {
		if err == gorm.RecordNotFound {
			return helpers.NewNotFoundResponse()
		}

		return helpers.NewBadRequestResponse(err)
	}

	req.Glanced = true

	return helpers.NewDefaultOKResponse()
}

type FollowRequest struct {
	FollowerId int64 `json:"followerId"`
	FolloweeId int64 `json:"followeeId"`
}

func Follow(u *url.URL, h http.Header, req *FollowRequest) (int, http.Header, interface{}, error) {

	n := models.NewNotification()
	n.AccountId = req.FolloweeId

	if err := n.Follow(req.FollowerId); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	return helpers.NewDefaultOKResponse()
}
