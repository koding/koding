package response

import (
	"errors"
	"net/http"
	"socialapi/workers/helper"
	"github.com/koding/bongo"
)

func NewBadRequest(err error) (int, http.Header, interface{}, error) {
	if err == nil {
		err = errors.New("Request is not valid")
	}

	helper.MustGetLogger().Error("Bad Request: %s", err)

	return http.StatusBadRequest, nil, nil, BadRequest{err}
}

// not to leak info about the resource
// do send NotFound err
func NewAccessDenied(err error) (int, http.Header, interface{}, error) {
	helper.MustGetLogger().Error("Access Denied Err: %s", err.Error())
	return NewNotFound()
}

func HandleResultAndError(res interface{}, err error) (int, http.Header, interface{}, error) {
	if err != nil {
		if err == bongo.RecordNotFound {
			return NewNotFound()
		}
		return NewBadRequest(err)
	}
	return NewOK(res)
}

func NewOK(res interface{}) (int, http.Header, interface{}, error) {
	return http.StatusOK, nil, res, nil
}

func NewNotFound() (int, http.Header, interface{}, error) {
	return http.StatusNotFound, nil, nil, NotFoundError{errors.New("Data not found")}
}

func NewDeleted() (int, http.Header, interface{}, error) {
	return http.StatusAccepted, nil, nil, nil
}

func NewDefaultOK() (int, http.Header, interface{}, error) {
	res := map[string]interface{}{
		"status": true,
	}

	return http.StatusOK, nil, res, nil
}
