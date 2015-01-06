package models

type ParticipantEvent struct {
	Id           int64                 `json:"id,string"`
	Participants []*ChannelParticipant `json:"participants"`
	Tokens       []string              `json:"tokens"`
	ChannelToken string                `json:"channelToken"`
}

func NewParticipantEvent() *ParticipantEvent {
	return &ParticipantEvent{
		Tokens: make([]string, 0),
	}
}

func (pe ParticipantEvent) GetId() int64 {
	return pe.Id
}

func (pe ParticipantEvent) BongoName() string {
	return "event.channel_participant"
}
