package models

import "errors"

var (
	IdNotSet             = errors.New("Id is not set")
	ErrChannelIdIsNotSet = errors.New("channel id is not set")
	ErrAccountIdIsNotSet = errors.New("account id is not set")
)
