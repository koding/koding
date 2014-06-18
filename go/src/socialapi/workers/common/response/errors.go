package response

import "net/http"

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
