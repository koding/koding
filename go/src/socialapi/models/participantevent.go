package models

type ParticipantEvent struct {
	Id           int64                 `json:"id,string"`
	Participants []*ChannelParticipant `json:"participants"`
}

func NewParticipantEvent() *ParticipantEvent {
	return &ParticipantEvent{}
}

func (pe ParticipantEvent) GetId() int64 {
	return pe.Id
}

func (pe ParticipantEvent) BongoName() string {
	return "event.channel_participant"
}
