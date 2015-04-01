package api

import (
	"net/http"
	"net/url"
	"socialapi/workers/common/response"
	"socialapi/workers/email/mailparse/models"

	"github.com/koding/runner"
)

func Parse(u *url.URL, h http.Header, req *models.Mail) (int, http.Header, interface{}, error) {
	if err := req.Validate(); err != nil {
		runner.MustGetLogger().Error("mail parse validate err : %S", err.Error())
		// faily silently, we dont want mail parser service to retry on
		// the failed validation
		return response.NewDefaultOK()
	}

	if err := req.Persist(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewDefaultOK()
}
