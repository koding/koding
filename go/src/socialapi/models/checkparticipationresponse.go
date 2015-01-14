package models

type CheckParticipationResponse struct {
	Channel *Channel
	Account *Account
}

func NewCheckParticipationResponse() *CheckParticipationResponse {
	return &CheckParticipationResponse{}
}
