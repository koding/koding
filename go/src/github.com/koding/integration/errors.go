package integration

import "errors"

var (
	ErrNameNotUnique = errors.New("title is not unique")

	ErrTokenNotSet   = errors.New("token is not set")
	ErrNameNotSet    = errors.New("name is not set")
	ErrChannelNotSet = errors.New("channel is not set")
	ErrTitleNotSet   = errors.New("title is not set")

	ErrContentNotFound = errors.New("content not found")
)
