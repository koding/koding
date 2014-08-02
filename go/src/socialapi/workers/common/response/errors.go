package response

import (
	"errors"
	"net/http"
)

var (
	genericError = errors.New("an error occured")
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
