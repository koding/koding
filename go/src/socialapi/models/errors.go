package models

import "errors"

var (
	ErrAlreadyInTheChannel                    = errors.New("message is already in the channel")
	IdNotSet                                  = errors.New("Id is not set")
	ErrChannelIdIsNotSet                      = errors.New("channel id is not set")
	ErrAccountIdIsNotSet                      = errors.New("account id is not set")
	ErrMessageIdIsNotSet                      = errors.New("message id is not set")
	ErrMessageIsNotSet                        = errors.New("message is not set")
	ErrCreatorIdIsNotSet                      = errors.New("creator id is not set")
	ErCouldntFindAccountIdFromContent         = errors.New("couldnt find account id from content")
	ErrCannotAddNewParticipantToPinnedChannel = errors.New("you can not add any participants to pinned activity channel")
	ErrAccountIsAlreadyInTheChannel           = errors.New("account is already in the channel")
	ErrGroupNameIsNotSet                      = errors.New("group name is not set")
	ErrNameIsNotSet                           = errors.New("name is not set")
	ErrChannelContainerIsNotSet               = errors.New("channel container is not set")
	ErrChannelIsNotSet   					  = errors.New("channel is not set")
)
