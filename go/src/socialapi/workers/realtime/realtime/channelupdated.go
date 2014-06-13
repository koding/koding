package realtime

import (
	"errors"
	"fmt"
	"socialapi/models"
)

type ChannelUpdatedEventType string

var (
	channelUpdatedEventMessageAddedToChannel     ChannelUpdatedEventType = "MessageAddedToChannel"
	channelUpdatedEventMessageRemovedFromChannel ChannelUpdatedEventType = "MessageRemovedFromChannel"
	channelUpdatedEventMessageUpdatedAtChannel   ChannelUpdatedEventType = "MessageListUpdated"
	channelUpdatedEventReplyAdded                ChannelUpdatedEventType = "ReplyAdded"
	channelUpdatedEventReplyRemoved              ChannelUpdatedEventType = "ReplyRemoved"
	channelUpdatedEventChannelParticipantUpdated ChannelUpdatedEventType = "ParticipantUpdated"
)

type channelUpdatedEvent struct {
	Channel              *models.Channel            `json:"channel"`
	ParentChannelMessage *models.ChannelMessage     `json:"channelMessage"`
	ReplyChannelMessage  *models.ChannelMessage     `json:"-"`
	EventType            ChannelUpdatedEventType    `json:"event"`
	ChannelParticipant   *models.ChannelParticipant `json:"-"`
	UnreadCount          int                        `json:"unreadCount"`
}

// sendChannelUpdatedEvent sends channel updated events
func (f *Controller) sendChannelUpdatedEvent(cue *channelUpdatedEvent) error {
	f.log.Debug("sending channel update event %+v", cue)

	if err := f.validateChannelUpdatedEvents(cue); err != nil {
		f.log.Error(err.Error())
		// this is not an error actually
		return nil
	}

	// fetch all participants of related channel
	// if you ask why we are not sending those messaages to the channel's channel
	// instead of sending events as notifications?, because we are also sending
	// unread counts of the related channel's messages by the notifiee
	participants, err := cue.Channel.FetchParticipantIds()
	if err != nil {
		f.log.Error("Error occured while fetching participants %s", err.Error())
		return err
	}

	// if
	if len(participants) == 0 {
		f.log.Notice("This channel (%d) doesnt have any participant but we are trying to send an event to it, please investigate", cue.Channel.Id)
		return nil
	}

	for _, accountId := range participants {
		if !f.isEligibleForBroadcasting(cue, accountId) {
			f.log.Debug("not sending event to the creator of this operation %s", cue.EventType)
			continue
		}

		cp := models.NewChannelParticipant()
		cp.ChannelId = cue.Channel.Id
		cp.AccountId = accountId
		if err := cp.FetchParticipant(); err != nil {
			f.log.Error("Err: %s, skipping account %d", err.Error(), accountId)
			return nil
		}
		cue.ChannelParticipant = cp

		f.sendChannelUpdatedEventToParticipant(cue)
	}

	return nil
}

func (f *Controller) isEligibleForBroadcasting(cue *channelUpdatedEvent, accountId int64) bool {
	// if parent message is empty do send
	// realtime  updates to the client
	if cue.ParentChannelMessage == nil {
		return true
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

func (f *Controller) validateChannelUpdatedEvents(cue *channelUpdatedEvent) error {
	// channel shouldnt be nil
	if cue.Channel == nil {
		return fmt.Errorf("Channel is nil")
	}

	// channel id should be set inorder to send event to the channel
	if cue.Channel.Id == 0 {
		return fmt.Errorf("Channel id is not set")
	}

	// filter group events
	// do not send any -updated- event to group channels
	if cue.Channel.TypeConstant == models.Channel_TYPE_GROUP {
		return fmt.Errorf("Not sending group (%s) event", cue.Channel.GroupName)
	}

	// do not send comment events to topic channels
	// other than topic channel, channels persist their messages as replies
	if cue.Channel.TypeConstant != models.Channel_TYPE_TOPIC {
		return nil
	}

	// if we dont have a parent message it means this is a post addition/creation
	if cue.ParentChannelMessage == nil {
		return nil
	}

	// send only post operations the the client
	if cue.ParentChannelMessage.TypeConstant != models.ChannelMessage_TYPE_POST {
		return fmt.Errorf("Not sending non-post (%s) event to topic channel",
			cue.ParentChannelMessage.TypeConstant,
		)
	}

	return nil
}

func (f *Controller) sendChannelUpdatedEventToParticipant(cue *channelUpdatedEvent) error {
	if cue.ChannelParticipant == nil {
		return errors.New("Channel Participant is nil")
	}

	count, err := f.calculateUnreadItemCount(cue)
	if err != nil {
		f.log.Notice("Error happened, setting unread count to 0 %s", err.Error())
		count = 0
	}

	cue.UnreadCount = count
	f.sendNotification(cue.ChannelParticipant.AccountId, ChannelUpdateEventName, cue)

	return nil
}

func (f *Controller) calculateUnreadItemCount(cue *channelUpdatedEvent) (int, error) {
	if cue.ParentChannelMessage == nil {
		return models.NewChannelMessageList().UnreadCount(cue.ChannelParticipant)
	}

	if cue.Channel.TypeConstant == models.Channel_TYPE_PRIVATE_MESSAGE {
		return models.NewMessageReply().UnreadCount(cue.ParentChannelMessage.Id, cue.ChannelParticipant.LastSeenAt)
	}

	if cue.Channel.TypeConstant == models.Channel_TYPE_TOPIC {
		return models.NewChannelMessageList().UnreadCount(cue.ChannelParticipant)
	}

	cml, err := cue.Channel.FetchMessageList(cue.ParentChannelMessage.Id)
	if err == nil {
		return models.NewMessageReply().UnreadCount(cml.MessageId, cml.AddedAt)
	}

	f.log.Critical("this shouldnt fall here")
	return 0, nil
}
