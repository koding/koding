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
	channelUpdatedEventChannelParticipantUpdated ChannelUpdatedEventType = "ReplyAdded"
)

type channelUpdatedEvent struct {
	Channel            *models.Channel            `json:"channel"`
	ChannelMessage     *models.ChannelMessage     `json:"channelMessage"`
	EventType          ChannelUpdatedEventType    `json:"eventType"`
	ChannelParticipant *models.ChannelParticipant `json:"-"`
	UnreadCount        int                        `json:"unreadCount"`
}

func (f *Controller) sendChannelUpdatedEvent(cue *channelUpdatedEvent) error {
	f.log.Debug("sending channel update event %+v", cue)

	if err := f.filterChannelUpdatedEvents(cue); err != nil {
		f.log.Error(err.Error())
		return err
	}

	participants, err := cue.Channel.FetchParticipantIds()
	if err != nil {
		f.log.Error("Error occured while fetching participants %s", err.Error())
		return err
	}

	if len(participants) == 0 {
		f.log.Info("Participant count is %d, skipping", len(participants))
		return nil
	}

	for _, accountId := range participants {
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

func (f *Controller) filterChannelUpdatedEvents(cue *channelUpdatedEvent) error {
	if cue.Channel == nil {
		return fmt.Errorf("Channel is nil")
	}

	if cue.Channel.Id == 0 {
		return fmt.Errorf("Channel id is not set")
	}

	// do not send any -updated- event to group channels
	if cue.Channel.TypeConstant == models.Channel_TYPE_GROUP {
		return fmt.Errorf("Not sending group (%s) event", cue.Channel.GroupName)
	}

	// do not send comment events to topic channels
	if cue.Channel.TypeConstant != models.Channel_TYPE_TOPIC {
		return nil
	}

	if cue.ChannelMessage == nil {
		return nil
	}

	if cue.ChannelMessage.TypeConstant != models.ChannelMessage_TYPE_POST {
		return fmt.Errorf("Not sending non-post (%s) event to topic channel",
			cue.ChannelMessage.TypeConstant,
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
	if cue.ChannelMessage == nil {
		return models.NewChannelMessageList().UnreadCount(cue.ChannelParticipant)
	}

	if cue.Channel.TypeConstant == models.Channel_TYPE_PRIVATE_MESSAGE {
		return models.NewMessageReply().UnreadCount(cue.ChannelMessage.Id, cue.ChannelParticipant.LastSeenAt)
	}

	if cue.Channel.TypeConstant == models.Channel_TYPE_TOPIC {
		return models.NewChannelMessageList().UnreadCount(cue.ChannelParticipant)
	}

	cml, err := cue.Channel.FetchMessageList(cue.ChannelMessage.Id)
	if err == nil {
		return models.NewMessageReply().UnreadCount(cml.MessageId, cml.AddedAt)
	}

	f.log.Critical("this shouldnt fall here")
	return 0, nil
}
