package response

import (
	"errors"
	"net/http"
)

var (
	genericError = errors.New("an error occurred")
)

type BadRequest struct {
	error
}

func (err BadRequest) Name() string { return "koding.BadRequest" }

func (err BadRequest) StatusCode() int { return http.StatusBadRequest }

type NotFoundError struct {
	error
}

func (err NotFoundError) Name() string { return "koding.NotFoundError" }

func (err NotFoundError) StatusCode() int { return http.StatusNotFound }

type LimitRateExceededError struct{ Err error }

func (e LimitRateExceededError) Error() string {
	return e.Name()
}

func (err LimitRateExceededError) Name() string {
	return "koding.LimitRateExceededError"
}

func (err LimitRateExceededError) StatusCode() int {
	// to many requests, it is not in standarts yet but browsers already
	// implemented it, Go has builtin status code but not exported yet.
	return 429
}
