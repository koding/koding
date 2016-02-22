package models

import "time"

type ChannelParticipantContainer struct {
	AccountId    int64     `json:"accountId"`
	AccountOldId string    `json:"accountOldId"`
	CreatedAt    time.Time `json:"createdAt"`
	UpdatedAt    time.Time `json:"updatedAt"`
}

func NewChannelParticipantContainer(cp ChannelParticipant) (*ChannelParticipantContainer, error) {
	acc, err := Cache.Account.ById(cp.AccountId)
	if err != nil {
		return &ChannelParticipantContainer{}, err
	}

	return &ChannelParticipantContainer{
		AccountId:    cp.AccountId,
		AccountOldId: acc.OldId,
		CreatedAt:    cp.CreatedAt,
		UpdatedAt:    cp.UpdatedAt,
	}, nil
}
