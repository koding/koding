package realtime

import (
	"errors"
	"fmt"
	"socialapi/models"
	"socialapi/request"
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
func (cue *channelUpdatedEvent) send() error {
	cue.Controller.log.Debug("sending channel update event %+v", cue)

	if err := cue.validateChannelUpdatedEvents(); err != nil {
		cue.Controller.log.Error(err.Error())
		// this is not an error actually
		return nil
	}

	// fetch all participants of related channel
	// if you ask why we are not sending those messaages to the channel's channel
	// instead of sending events as notifications?, because we are also sending
	// unread counts of the related channel's messages by the notifiee
	participants, err := cue.Channel.FetchParticipantIds(
		// make sure exempt users are getting reatime notifications
		&request.Query{ShowExempt: true},
	)

	if err != nil {
		cue.Controller.log.Error("Error occured while fetching participants %s", err.Error())
		return err
	}

	// if
	if len(participants) == 0 {
		cue.Controller.log.Notice("This channel (%d) doesnt have any participant but we are trying to send an event to it, please investigate", cue.Channel.Id)
		return nil
	}

	for _, accountId := range participants {
		if !cue.isEligibleForBroadcasting(accountId) {
			cue.Controller.log.Debug("not sending event to the creator of this operation %s", cue.EventType)
			continue
		}

		cp := models.NewChannelParticipant()
		cp.ChannelId = cue.Channel.Id
		cp.AccountId = accountId
		if err := cp.FetchParticipant(); err != nil {
			cue.Controller.log.Error("Err: %s, skipping account %d", err.Error(), accountId)
			return nil
		}
		cue.ChannelParticipant = cp

		err := cue.sendForParticipant()
		if err != nil {
			return err
		}

	}

	return nil
}

func (cue *channelUpdatedEvent) isEligibleForBroadcasting(accountId int64) bool {
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

func (cue *channelUpdatedEvent) validateChannelUpdatedEvents() error {
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

func (cue *channelUpdatedEvent) sendForParticipant() error {
	if cue.ChannelParticipant == nil {
		return errors.New("Channel Participant is nil")
	}

	count, err := cue.calculateUnreadItemCount()
	if err != nil {
		cue.Controller.log.Notice("Error happened, setting unread count to 0 %s", err.Error())
		count = 0
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

func (cue *channelUpdatedEvent) calculateUnreadItemCount() (int, error) {
	if cue.ParentChannelMessage == nil {
		return models.NewChannelMessageList().UnreadCount(cue.ChannelParticipant)
	}

	// for topic channel unread count will be calculated from unread post count
	if cue.Channel.TypeConstant == models.Channel_TYPE_TOPIC {
		return models.NewChannelMessageList().UnreadCount(cue.ChannelParticipant)
	}

	// from this point we need parent message

	cml, err := cue.Channel.FetchMessageList(cue.ParentChannelMessage.Id)
	if err != nil {
		return 0, err
	}

	isTroll := cml.MetaBits.Is(models.Troll)

	// for pinned posts calculate unread count from message's added at into that channel
	if cue.Channel.TypeConstant == models.Channel_TYPE_PINNED_ACTIVITY {
		// for pinned posts we are calculating unread count from reviseddAt of the
		// regarding channel message list, since only participant for the channel
		// is the owner and we cant use channel_participant for unread counts
		// on the other hand messages should have their own unread count
		// we are specialcasing the pinned posts here
		return models.NewMessageReply().UnreadCount(cml.MessageId, cml.RevisedAt, isTroll)
	}

	// for private messages calculate the unread reply count
	if cue.Channel.TypeConstant == models.Channel_TYPE_PRIVATE_MESSAGE {
		count, err := models.NewMessageReply().UnreadCount(cue.ParentChannelMessage.Id, cue.ChannelParticipant.LastSeenAt, isTroll)
		if err != nil {
			return 0, err
		}

		// if unread count is 0
		// set it to 1 for now
		// because we want to show a notification with a sign
		if count == 0 {
			count = 1
		}

		return count, nil
	}

	cue.Controller.log.Critical("Calculating unread count shouldnt fall here")
	return 0, nil
}
