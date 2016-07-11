package api

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/common/response"
)

type Request struct {
}

func Info(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	// token := h.Get("Authorization")

	//user:= Get User with token

	// return response.New(userinfo)
	return response.NewOK(nil)
}
