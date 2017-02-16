package response

import (
	"errors"
	"net/http"
	"os"
	"socialapi/config"

	"github.com/koding/bongo"
	"github.com/koding/logging"
	"github.com/koding/runner"
)

var (
	ErrContentNotFound = errors.New("content not found")
	ErrNotImplemented  = errors.New("not implemented")
	socialApiEnv       = os.Getenv("SOCIAL_API_ENV")
)

// NewBadRequest is creating a new http response with predifined
// http response properties
func NewBadRequest(err error) (int, http.Header, interface{}, error) {
	l := runner.MustGetLogger()
	l = l.New("response")
	l.SetCallDepth(2) // get previous error line

	return NewBadRequestWithLogger(l, err)
}

// NewBadRequestWithLogger is creating a new http response with predifined http
// response properties, it uses a special logger for outputting callstack
// properly
func NewBadRequestWithLogger(l logging.Logger, err error) (int, http.Header, interface{}, error) {
	if err == nil {
		err = errors.New("request is not valid")
	}

	// make sure errors are outputted
	l.Debug("Bad Request: %s", err)

	// do not expose errors to the client
	env := config.MustGet().Environment

	// do not expose errors to the client.
	if env != "dev" && env != "test" && socialApiEnv != "wercker" {
		err = genericError
	}

	return http.StatusBadRequest, nil, nil, BadRequest{err}
}

// NewInvalidRequest sends bad request response back to client.
// Unlike NewBadRequest method, errors are exposed to users.
// For this reason it is used for returning input validation errors
func NewInvalidRequest(err error) (int, http.Header, interface{}, error) {

	if err == nil {
		err = errors.New("request is not valid")
	}

	// make sure errors are outputted
	runner.MustGetLogger().Error("Invalid Request: %s", err)

	return http.StatusBadRequest, nil, nil, BadRequest{err}
}

// NewAccessDenied sends access denied response back to client
//
// here not to leak info about the resource do send NotFound err
func NewAccessDenied(err error) (int, http.Header, interface{}, error) {
	l := runner.MustGetLogger()
	l = l.New("response")
	l.SetCallDepth(1) // get previous error line
	l.Error("Access Denied Err: %s", err.Error())

	return NewNotFound()
}

// HandleResultAndError wraps the function calls and get its response,
// assuming the second parameter as error checks it if it is null or not
// if err nor found, returns OK response
func HandleResultAndError(res interface{}, err error) (int, http.Header, interface{}, error) {
	if err == bongo.RecordNotFound {
		return NewNotFound()
	}

	l := runner.MustGetLogger()
	l = l.New("response")
	l.SetCallDepth(2) // get 2 previous call stack

	if err != nil {
		return NewBadRequestWithLogger(l, err)
	}

	return NewOK(res)
}

// HandleResultAndClientError is same as `HandleResultAndError`, but it
// returns the actual error to client as opposed to generic error.
func HandleResultAndClientError(res interface{}, err error) (int, http.Header, interface{}, error) {
	if err != nil {
		return http.StatusBadRequest, nil, nil, err
	}

	return NewOK(res)
}

// NewOK returns http StatusOK response
func NewOK(res interface{}) (int, http.Header, interface{}, error) {
	return http.StatusOK, nil, res, nil
}

func NewNotImplemented() (int, http.Header, interface{}, error) {
	return http.StatusNotImplemented, nil, nil, ErrNotImplemented
}

func NewOKWithCookie(res interface{}, cookies []*http.Cookie) (int, http.Header, interface{}, error) {
	h := http.Header{}
	if len(cookies) > 0 {
		for _, cookie := range cookies {
			h.Add("Set-Cookie", cookie.String())
		}
	}

	return http.StatusOK, h, res, nil
}

// NewNotFound returns http StatusNotFound response
func NewNotFound() (int, http.Header, interface{}, error) {
	return http.StatusNotFound, nil, nil, NotFoundError{ErrContentNotFound}
}

// NewDeleted returns http StatusAccepted response
func NewDeleted() (int, http.Header, interface{}, error) {
	return http.StatusAccepted, nil, nil, nil
}

// NewDefaultOK returns http StatusOK response with `{status:true}` response
func NewDefaultOK() (int, http.Header, interface{}, error) {
	res := &SuccessResponse{}
	res.Status = true

	return NewOK(res)
}
