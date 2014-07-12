package response

import (
	"errors"
	"net/http"
	"socialapi/config"
	"socialapi/workers/helper"

	"github.com/koding/bongo"
)

// NewBadRequest is creating a new http response with predifined
// http response properties
func NewBadRequest(err error) (int, http.Header, interface{}, error) {
	if err == nil {
		err = errors.New("request is not valid")
	}

	// make sure errors are outputted
	helper.MustGetLogger().Error("Bad Request: %s", err)

	// do not expose errors to the client
	if config.MustGet().Environment != config.VagrantEnvName {
		err = genericError
	}

	return http.StatusBadRequest, nil, nil, BadRequest{err}
}

// NewAccessDenied sends access denied response back to client
//
// here not to leak info about the resource
// do send NotFound err
func NewAccessDenied(err error) (int, http.Header, interface{}, error) {
	helper.MustGetLogger().Error("Access Denied Err: %s", err.Error())
	return NewNotFound()
}

// HandleResultAndError wraps the function calls and get its reponse,
// assuming the second parameter as error checks it if it is null or not
// if err nor found, returns OK response
func HandleResultAndError(res interface{}, err error) (int, http.Header, interface{}, error) {
	if err == bongo.RecordNotFound {
		return NewNotFound()
	}

	if err != nil {
		return NewBadRequest(err)
	}

	return NewOK(res)
}

// NewOK returns http StatusOK response
func NewOK(res interface{}) (int, http.Header, interface{}, error) {
	return http.StatusOK, nil, res, nil
}

// NewNotFound returns http StatusNotFound response
func NewNotFound() (int, http.Header, interface{}, error) {
	return http.StatusNotFound, nil, nil, NotFoundError{errors.New("content not found")}
}

// NewDeleted returns http StatusAccepted response
func NewDeleted() (int, http.Header, interface{}, error) {
	return http.StatusAccepted, nil, nil, nil
}

// NewDefaultOK returns http StatusOK response with `{status:true}` response
func NewDefaultOK() (int, http.Header, interface{}, error) {
	res := map[string]interface{}{
		"status": true,
	}

	return http.StatusOK, nil, res, nil
}
