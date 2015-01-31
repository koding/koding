package models

type CheckParticipationResponse struct {
	Channel      *Channel
	Account      *Account
	AccountToken string
}

func NewCheckParticipationResponse() *CheckParticipationResponse {
	return &CheckParticipationResponse{}
}
