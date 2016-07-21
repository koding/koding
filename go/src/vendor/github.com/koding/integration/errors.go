package integration

import "errors"

var (
	ErrTokenNotSet = errors.New("token is not set")
	ErrNameNotSet  = errors.New("name is not set")

	ErrContentNotFound = errors.New("content not found")
)
