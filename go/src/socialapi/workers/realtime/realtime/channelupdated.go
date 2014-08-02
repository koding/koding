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
	p := models.NewChannelParticipant()
	p.ChannelId = cue.Channel.Id
	// make sure exempt users are getting reatime notifications
	participants, err := p.List(&request.Query{ShowExempt: true})
	if err != nil {
		cue.Controller.log.Error("Error occured while fetching participants %s", err.Error())
		return err
	}

	// if
	if len(participants) == 0 {
		cue.Controller.log.Notice("This channel (%d) doesnt have any participant but we are trying to send an event to it, please investigate", cue.Channel.Id)
		return nil
	}

	for i, cp := range participants {
		if !cue.isEligibleForBroadcasting(cp.AccountId) {
			cue.Controller.log.Debug("not sending event to the creator of this operation %s", cue.EventType)
			continue
		}

		cue.ChannelParticipant = &participants[i]

		err := cue.sendForParticipant()
		if err != nil {
			return err
		}

	}

	return nil
}

func (cue *channelUpdatedEvent) isEligibleForBroadcasting(accountId int64) bool {
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
	if cue.ChannelParticipant == nil {
		return 0, errors.New("channel participant is not set")
	}

	if cue.ParentChannelMessage == nil {
		return models.NewChannelMessageList().UnreadCount(cue.ChannelParticipant)
	}

	// Topic channels have the normal structure, one channel, many messages,
	// many participants. For topic channel unread count will be calculated from
	// unread post count whithin a channel, base timestamp here is perisisted in
	// ChannelParticipant table as LastSeenAt timestamp. If one message is
	// edited by another user with a new tag, this message will not be marked as
	// read, because we are not looking to createdAt of the channel message
	// list, we are taking AddedAt into consideration here
	if cue.Channel.TypeConstant == models.Channel_TYPE_TOPIC {
		return models.NewChannelMessageList().UnreadCount(cue.ChannelParticipant)
	}

	// from this point we need parent message

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
	if cue.Channel.TypeConstant == models.Channel_TYPE_PINNED_ACTIVITY {
		return models.NewMessageReply().UnreadCount(cml.MessageId, cml.RevisedAt, isRecieverTroll)
	}

	// for private messages calculate the unread reply count
	if cue.Channel.TypeConstant == models.Channel_TYPE_PRIVATE_MESSAGE {
		count, err := models.NewMessageReply().UnreadCount(cue.ParentChannelMessage.Id, cue.ChannelParticipant.LastSeenAt, isRecieverTroll)
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
