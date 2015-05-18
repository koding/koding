package integration

import "errors"

var (
	ErrNameNotUnique = errors.New("title is not unique")
	ErrInvalidToken  = errors.New("invalid token")

	ErrTokenNotSet   = errors.New("token is not set")
	ErrNameNotSet    = errors.New("name is not set")
	ErrBodyNotSet    = errors.New("body is not set")
	ErrChannelNotSet = errors.New("channel is not set")
	ErrTitleNotSet   = errors.New("title is not set")

	ErrIntegrationNotFound = errors.New("channel integration is not found")
	ErrContentNotFound     = errors.New("content not found")
	ErrAccountNotFound     = errors.New("account not found")
	ErrBotChannelNotFound  = errors.New("bot channel is not found")

	ErrBadGateway = errors.New("bad gateway")
	ErrUnknown    = errors.New("unknown error")
)
