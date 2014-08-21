package models

import "errors"

var (
	ErrMessageAlreadyInTheChannel = errors.New("message is already in the channel")
	ErrIdIsNotSet                 = errors.New("Id is not set")
	ErrAccountIdIsNotSet          = errors.New("account id is not set")
	ErrOldIdIsNotSet              = errors.New("old id is not set")
	ErrNickIsNotSet               = errors.New("nick is not set")
	ErrGuestsAreNotAllowed        = errors.New("guests are not allowed")

	ErrMessageIdIsNotSet       = errors.New("message id is not set")
	ErrMessageIsNotSet         = errors.New("message is not set")
	ErrParentMessageIsNotSet   = errors.New("parent message is not set")
	ErrParentMessageIdIsNotSet = errors.New("parent message id is not set")
	ErrCreatorIdIsNotSet       = errors.New("creator id is not set")

	ErrChannelIsNotSet                = errors.New("channel is not set")
	ErrChannelIdIsNotSet              = errors.New("channel id is not set")
	ErrChannelContainerIsNotSet       = errors.New("channel container is not set")
	ErCouldntFindAccountIdFromContent = errors.New("couldnt find account id from content")
	ErrAccountIsAlreadyInTheChannel   = errors.New("account is already in the channel")

	ErrChannelParticipantIsNotSet             = errors.New("channel participant is not set")
	ErrCannotAddNewParticipantToPinnedChannel = errors.New("you can not add any participants to pinned activity channel")

	ErrNameIsNotSet       = errors.New("name is not set")
	ErrGroupNameIsNotSet  = errors.New("group name is not set")
	ErrLastSeenAtIsNotSet = errors.New("lastSeenAt is not set")
	ErrAddedAtIsNotSet    = errors.New("addedAt is not set")

	ErrRecipientsNotDefined = errors.New("recipients are not defined")
	ErrCannotOpenChannel    = errors.New("you can not open the channel")
)
