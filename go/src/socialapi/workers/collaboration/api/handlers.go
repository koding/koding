package api

import (
	"net/http"
	"net/url"
	"socialapi/workers/collaboration/models"
	"socialapi/workers/common/response"
)

func Ping(u *url.URL, h http.Header, req *models.Ping) (int, http.Header, interface{}, error) {
	return response.NewOK(req)
}
