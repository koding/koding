package api

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/response"
)

func List(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {

	return response.HandleResultAndError(nil, nil)
}

func Get(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	id, err := request.GetId(u)
	if err != nil {
		return response.NewBadRequest(err)
	}

	req := models.NewPermission()
	if err := req.ById(id); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(req)
}

func Update(u *url.URL, h http.Header, req *models.Permission) (int, http.Header, interface{}, error) {
	if err := req.Update(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(req)
}

func Create(u *url.URL, h http.Header, req *models.Permission) (int, http.Header, interface{}, error) {
	if err := req.Create(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(req)
}
