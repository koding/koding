package api

import (
	"fmt"
	"net/http"
	"net/url"
	"socialapi/workers/common/response"
	"socialapi/workers/mail/models"
)

func Parse(u *url.URL, h http.Header, req *models.Mail) (int, http.Header, interface{}, error) {
	if err := req.Validate(); err != nil {
		return response.NewBadRequest(err)
	}
	fmt.Println(req)
	return response.NewDefaultOK()
}