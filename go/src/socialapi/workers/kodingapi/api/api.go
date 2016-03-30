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

// GetMachine gets the machine with machine id
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

// GetMachineStatus gets status of the  machine
func GetMachineStatus(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if err := checkAuthorization(h); err != nil {
		return response.NewBadRequest(err)
	}

	machineId := u.Query().Get("id")
	machine, err := modelhelper.GetMachine(machineId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	status := machine.State()

	// return response.New(userinfo)
	return response.HandleResultAndError(status, err)
}

func checkAuthorization(h http.Header) error {
	return nil
}
