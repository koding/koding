package realtime

import (
	"errors"
	"fmt"
	"socialapi/models"
	"socialapi/request"

	"github.com/koding/bongo"
)

type channelUpdatedEventType string

var (
	channelUpdatedEventMessageAddedToChannel     channelUpdatedEventType = "MessageAddedToChannel"
	channelUpdatedEventMessageRemovedFromChannel channelUpdatedEventType = "MessageRemovedFromChannel"
	channelUpdatedEventMessageUpdatedAtChannel   channelUpdatedEventType = "MessageListUpdated"
	channelUpdatedEventReplyAdded                channelUpdatedEventType = "ReplyAdded"
	channelUpdatedEventReplyRemoved              channelUpdatedEventType = "ReplyRemoved"
	channelUpdatedEventChannelParticipantUpdated channelUpdatedEventType = "ParticipantUpdated"
)

type channelUpdatedEvent struct {
	Controller           *Controller                `json:"-"`
	Channel              *models.Channel            `json:"channel"`
	ParentChannelMessage *models.ChannelMessage     `json:"channelMessage"`
	ReplyChannelMessage  *models.ChannelMessage     `json:"-"`
	EventType            channelUpdatedEventType    `json:"event"`
	ChannelParticipant   *models.ChannelParticipant `json:"-"`
	UnreadCount          int                        `json:"unreadCount"`
}

// sendChannelUpdatedEvent sends channel updated events
func (cue *channelUpdatedEvent) notifyAllParticipants() error {
	cue.Controller.log.Debug("notifying all participants with: %+v", cue)

	// if it is not a valid event, return silently
	if !cue.isValidNotifyAllParticipantsEvent() {
		cue.Controller.log.Debug("not a valid event (%s) for notifying all participants", cue.EventType)
		return nil
	}

	// fetch all participants of related channel if you ask why we are not
	// sending those messaages to the channel's channel instead of sending
	// events as notifications?, because we are also sending unread counts of
	// the related channel's messages by the notifiee
	p := models.NewChannelParticipant()
	p.ChannelId = cue.Channel.Id
	// TODO use proper caching here
	participants, err := p.List(
		&request.Query{
			// make sure exempt users are getting reatime notifications
			ShowExempt: true,

			// lets say nodejs topic has 56K participants(yes it has), if we
			// dont limit we can take koding down. 100 is just a random number
			Limit: 100,

			// send the event to the recently active users
			Sort: map[string]string{"updated_at": "DESC"},
		},
	)

	if err != nil {
		cue.Controller.log.Error("Error occurred while fetching participants %s", err.Error())
		return err
	}

	if len(participants) == 0 {
		return nil
	}

	for i, cp := range participants {
		if !cue.isEligibleForBroadcastingToParticipant(cp.AccountId) {
			cue.Controller.log.Debug("not sending event (%s) to the participant  %d", cue.EventType, cp.AccountId)
			continue
		}

		cue.ChannelParticipant = &participants[i]

		err := cue.sendForParticipant()
		if err != nil {
			cue.Controller.log.Error("Error while sending notification (%s)", err.Error())
		}
	}

	return nil
}

func (cue *channelUpdatedEvent) isEligibleForBroadcastingToParticipant(accountId int64) bool {
	// check if channel is empty
	if cue.Channel == nil {
		cue.Controller.log.Error("Channel should not be empty %+v", cue)
		return false
	}

	// if parent message is empty do send
	// realtime  updates to the client
	if cue.ParentChannelMessage == nil {
		return true
	}

	// if we are gonna send this notification to topic channel
	// do not send to initiator
	if cue.Channel.TypeConstant == models.Channel_TYPE_TOPIC {
		if cue.ParentChannelMessage.AccountId == accountId {
			return false
		}
	}

	// if reply is not set do send this event
	if cue.ReplyChannelMessage == nil {
		return true
	}

	// if parent message's crateor is account
	// dont send it
	// this has introduced some bugs to system, like if someone
	// comments to my post(i also pinned it)
	// i wasnt getting any notification
	// if cue.ParentChannelMessage.AccountId == accountId {
	// 	return false
	// }

	// if reply message's crateor is account
	// dont send it
	if cue.ReplyChannelMessage.AccountId == accountId {
		return false
	}

	return true
}

func (cue *channelUpdatedEvent) isValidNotifyAllParticipantsEvent() bool {
	// channel shouldnt be nil
	if cue.Channel == nil {
		cue.Controller.log.Debug("Channel is nil")
		return false
	}

	// channel id should be set inorder to send event to the channel
	if cue.Channel.Id == 0 {
		cue.Controller.log.Debug("Channel id is not set")
		return false
	}

	// filter evets according to their TypeConstants
	if !cue.Channel.ShowUnreadCount() {
		cue.Controller.log.Debug(
			"Not sending channelUpdatedEvent for  (%s)",
			cue.Channel.TypeConstant,
		)

		return false
	}

	// we can early return here, because no need to check for other cases we
	// have a special case for pinned activity channels, we dont want to send channel
	// updated events for replies to other type of channels
	if cue.Channel.TypeConstant == models.Channel_TYPE_PINNED_ACTIVITY {
		return true
	}

	// if we dont have a parent message it means this is a post
	// addition/creation
	if cue.ParentChannelMessage == nil {
		return true
	}

	// send only post operations the the client
	if cue.ParentChannelMessage.TypeConstant == models.ChannelMessage_TYPE_POST ||
		cue.ParentChannelMessage.TypeConstant == models.ChannelMessage_TYPE_PRIVATE_MESSAGE ||
		cue.ParentChannelMessage.TypeConstant == models.ChannelMessage_TYPE_SYSTEM ||
		cue.ParentChannelMessage.TypeConstant == models.ChannelMessage_TYPE_BOT {
		return true
	}

	cue.Controller.log.Debug("Not sending non-post (%s) event to non-pinned activity channels",
		cue.ParentChannelMessage.TypeConstant,
	)
	return false
}

func (cue *channelUpdatedEvent) sendForParticipant() error {
	if cue.ChannelParticipant == nil {
		return errors.New("Channel Participant is nil")
	}

	count, err := cue.calculateUnreadItemCount()
	if err != nil {
		count = 0

		// suppress RecordNotFound errors
		if err == bongo.RecordNotFound {
			if cue.EventType != channelUpdatedEventMessageRemovedFromChannel {
				cue.Controller.log.Notice("Error happened, setting unread count to 0 %s", err.Error())
			}
		} else {
			cue.Controller.log.Notice("Error happened, setting unread count to 0 %s", err.Error())
		}
	}

	cue.UnreadCount = count

	err = cue.Controller.sendNotification(
		cue.ChannelParticipant.AccountId,
		cue.Channel.GroupName,
		ChannelUpdateEventName,
		cue,
	)
	if err != nil {
		cue.Controller.log.Error(err.Error())
	}

	return nil
}

// calculateUnreadItemCount calculates the unread count for given participant in
// given channel
func (cue *channelUpdatedEvent) calculateUnreadItemCount() (int, error) {
	if cue.Channel == nil {
		return 0, models.ErrChannelIsNotSet
	}

	// channel type can only be
	//
	// PinnedActivity
	// PrivateMessage
	// Topic
	if !cue.Channel.ShowUnreadCount() {
		return 0, fmt.Errorf("not supported channel type for unread count calculation %+v", cue.Channel.TypeConstant)
	}

	// we need channel participant for their latest appearance in regarding channel
	if cue.ChannelParticipant == nil {
		return 0, models.ErrChannelParticipantIsNotSet
	}

	// Topic channels and private messages have the normal structure, one
	// channel, many messages, many participants. For them unread count will be
	// calculated from unread post count whithin a channel, base timestamp here
	// is persisted in ChannelParticipant table as LastSeenAt timestamp.
	//
	// If one message is edited by another user with a new tag, this message
	// will not be marked as read, because we are not looking to createdAt of
	// the channel message list, we are taking AddedAt into consideration here
	if cue.Channel.TypeConstant != models.Channel_TYPE_PINNED_ACTIVITY {
		return models.NewChannelMessageList().UnreadCount(cue.ChannelParticipant)
	}

	// from this point we need parent message
	if cue.ParentChannelMessage == nil {
		return 0, models.ErrParentMessageIsNotSet
	}

	if cue.ParentChannelMessage.Id == 0 {
		return 0, models.ErrParentMessageIdIsNotSet
	}

	cml, err := cue.Channel.FetchMessageList(cue.ParentChannelMessage.Id)
	if err != nil {
		return 0, err
	}

	// check if the participant is troll
	isRecieverTroll := cue.ChannelParticipant.MetaBits.Is(models.Troll)

	// for pinned posts we are calculating unread count from reviseddAt of the
	// regarding channel message list, since only participant for the channel is
	// the owner and we cant use channel_participant for unread counts on the
	// other hand messages should have their own unread count we are
	// specialcasing the pinned posts here
	return models.NewMessageReply().UnreadCount(cml.MessageId, cml.RevisedAt, isRecieverTroll)
}
