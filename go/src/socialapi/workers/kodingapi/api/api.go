package api

import (
	"errors"
	"koding/db/mongodb/modelhelper"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/common/response"
	"strings"
)

var (
	ErrTokenNotSet  = errors.New("token is not set")
	ErrInvalidToken = errors.New("invalid token")
)

type Request struct {
}

func Info(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if _, err := getAuthorization(h); err != nil {
		return response.NewBadRequest(err)
	}

	//user:= Get User with token

	// return response.New(userinfo)
	return response.NewOK(nil)
}

// GetMachine gets the machine with machine id
func GetMachine(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if _, err := getAuthorization(h); err != nil {
		return response.NewBadRequest(err)
	}

	machineId := u.Query().Get("id")
	machine, err := modelhelper.GetMachine(machineId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(machine, err)
}

// GetMachineStatus gets status of the  machine
func GetMachineStatus(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if _, err := getAuthorization(h); err != nil {
		return response.NewBadRequest(err)
	}

	machineId := u.Query().Get("id")
	machine, err := modelhelper.GetMachine(machineId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	status := machine.State()

	return response.HandleResultAndError(status, err)
}

// GetMachineStatus gets status of the  machine
func ListMachines(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	token, err := getAuthorization(h)
	if err != nil {
		return response.NewBadRequest(err)
	}

	// TODO
	// PROCESS TOKEN HERE
	// GET USER FROM DB W/ TOKEN & LIST MACHINES OF USER

	//TODO We need to write a func to get userId with incoming user token
	// ~Mehmet Ali

	machines, err := modelhelper.GetMachinesByUsername(userId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(token)
}

func getAuthorization(h http.Header) (string, error) {
	authHeader := h.Get("Authorization")
	if authHeader == "" {
		return "", ErrTokenNotSet
	}

	var token string

	if authHeader != "" {
		s := strings.SplitN(authHeader, " ", 2)
		if len(s) != 2 || strings.ToLower(s[0]) != "bearer" {
			return "", ErrInvalidToken
		}
		//Use authorization header token only if token type is bearer else query string access token would be returned
		if len(s) > 0 && strings.ToLower(s[0]) == "bearer" {
			token = s[1]
		}
	}

	return token, nil
}
