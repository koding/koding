package realtime

import (
	"errors"
	"socialapi/models"
)

type channelUpdatedEventType string

var (
	channelUpdatedEventChannelParticipantUpdated channelUpdatedEventType = "ParticipantUpdated"
)

type channelUpdatedEvent struct {
	Controller         *Controller                `json:"-"`
	Channel            *models.Channel            `json:"channel"`
	EventType          channelUpdatedEventType    `json:"event"`
	ChannelParticipant *models.ChannelParticipant `json:"-"`
	UnreadCount        int                        `json:"unreadCount"`
}

func (cue *channelUpdatedEvent) sendForParticipant() error {
	if cue.ChannelParticipant == nil {
		return errors.New("Channel Participant is nil")
	}

	err := cue.Controller.sendNotification(
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
