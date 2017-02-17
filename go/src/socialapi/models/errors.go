package models

import (
	"errors"
	"fmt"
)

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
	ErrSystemTypeIsNotSet      = errors.New("systemType is not set in payload")

	ErrChannelIsNotSet                = errors.New("channel is not set")
	ErrChannelIdIsNotSet              = errors.New("channel id is not set")
	ErrChannelContainerIsNotSet       = errors.New("channel container is not set")
	ErCouldntFindAccountIdFromContent = errors.New("couldnt find account id from content")
	ErrAccountIsAlreadyInTheChannel   = errors.New("account is already in the channel")

	ErrChannelParticipantIsNotSet             = errors.New("channel participant is not set")
	ErrCannotAddNewParticipantToPinnedChannel = errors.New("you can not add any participants to pinned activity channel")

	ErrChannelMessageIdIsNotSet        = errors.New("channel message id is not set")
	ErrChannelMessageUpdatedNotAllowed = errors.New("join/leave message update is not allowed")

	ErrNameIsNotSet       = errors.New("name is not set")
	ErrGroupNameIsNotSet  = errors.New("group name is not set")
	ErrGroupNotFound      = errors.New("group is not found")
	ErrLastSeenAtIsNotSet = errors.New("lastSeenAt is not set")
	ErrAddedAtIsNotSet    = errors.New("addedAt is not set")

	ErrRecipientsNotDefined = errors.New("recipients are not defined")
	ErrCannotOpenChannel    = errors.New("you can not open the channel")
	ErrSlugIsNotSet         = errors.New("slug is not set")

	ErrChannelOrMessageIdIsNotSet = errors.New("channelId/messageId is not set")

	ErrNotLoggedIn       = errors.New("not logged in")
	ErrCannotManageGroup = errors.New("not admin of the group")

	ErrAccessDenied = errors.New("access denied")

	ErrRoleNotSet              = errors.New("role not set")
	ErrAccountNotFound         = errors.New("account not found")
	ErrChannelNotFound         = errors.New("channel not found")
	ErrParticipantNotFound     = errors.New("participant not found")
	ErrParticipantBlocked      = errors.New("participant is blocked")
	ErrAccountIsNotParticipant = errors.New("account is not participant of channel")
	ErrTokenIsNotFound         = errors.New("token is not found")

	// moderation
	ErrLeafIsNotSet          = errors.New("leaf channel is not set")
	ErrRootIsNotSet          = errors.New("root channel is not set")
	ErrChannelHasLeaves      = errors.New("channel has leaves")
	ErrChannelIsLinked       = errors.New("channel is linked")
	ErrGroupsAreNotSame      = errors.New("groups are not same")
	ErrLeafIsRootToo         = errors.New("leaf channel is root of another channel")
	ErrLinkingProcessNotDone = errors.New("channel linking process is not finished")

	ErrLoggerNotExist = errors.New("logger does not exist")
	ErrRedisNotExist  = errors.New("redis connection is not established")
)

type ChannelIsLeafError error

func ErrChannelIsLeafFunc(rootName, typeConstant string) error {
	return ChannelIsLeafError(
		fmt.Errorf(
			// poor man's json encoding - not to handle error case of
			// json.MarshalJSON, if we add new properties into this string, we
			// should use std package
			"{\"rootName\":\"%s\", \"typeConstant\":\"%s\"}",
			rootName,
			typeConstant,
		))
}

func IsChannelLeafErr(err error) bool {
	if err == nil {
		return false
	}

	_, ok := err.(ChannelIsLeafError)
	return ok
}
