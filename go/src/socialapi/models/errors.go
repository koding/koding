package models

import "errors"

var (
	IdNotSet                    = errors.New("Id is not set")
	ErrChannelIsNotSet          = errors.New("channel is not set")
	ErrMessageIsNotSet          = errors.New("message is not set")
	ErrChannelContainerIsNotSet = errors.New("channel container is not set")
)
