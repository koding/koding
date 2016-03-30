package api

import (
	"koding/db/mongodb/modelhelper"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/common/response"
)

type Request struct {
}

func Info(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if err := checkAuthorization(h); err != nil {
		return response.NewBadRequest(err)
	}

	//user:= Get User with token

	// return response.New(userinfo)
	return response.NewOK(nil)
}

func GetMachine(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if err := checkAuthorization(h); err != nil {
		return response.NewBadRequest(err)
	}

	machineId := u.Query().Get("id")
	machine, err := modelhelper.GetMachine(machineId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	// return response.New(userinfo)
	return response.HandleResultAndError(machine, err)
}

func checkAuthorization(h http.Header) error {
	return nil
}
