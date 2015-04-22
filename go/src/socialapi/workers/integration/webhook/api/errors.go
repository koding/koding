package api

import "errors"

var (
	ErrBodyNotSet    = errors.New("body is not set")
	ErrChannelNotSet = errors.New("channel is not set")
	ErrTokenNotSet   = errors.New("token is not set")
	ErrGroupNotSet   = errors.New("group name is not set")
	ErrTokenNotValid = errors.New("token is not valid")
	ErrNameNotSet    = errors.New("name is not set")
	ErrNameNotValid  = errors.New("name is not valid")
)
