package rest

import (
	"encoding/json"
	"fmt"
	"socialapi/models"

	"labix.org/v2/mgo/bson"
)

func CreateChannelParticipants(channelId int64, c int) ([]*models.ChannelParticipant, error) {
	var participants []*models.ChannelParticipant
	for i := 0; i < c; i++ {
		participant, err := CreateChannelParticipant(channelId)
		if err != nil {
			return nil, err
		}

		participants = append(participants, participant)
	}

	return participants, nil
}

func CreateChannelParticipant(channelId int64) (*models.ChannelParticipant, error) {
	account := models.NewAccount()
	account.OldId = bson.NewObjectId().Hex()
	account, _ = CreateAccount(account)
	return AddChannelParticipant(channelId, account.Id, account.Id)
}

func AddChannelParticipant(channelId, requesterId, accountId int64) (*models.ChannelParticipant, error) {
	c := models.NewChannelParticipant()
	c.AccountId = accountId

	res := make([]*models.ChannelParticipant, 1)
	res[0] = c

	url := fmt.Sprintf("/channel/%d/participant/add?accountId=%d", channelId, requesterId)
	cps, err := sendModel("POST", url, &res)
	if err != nil {
		return nil, err
	}

	a := *(cps.(*[]*models.ChannelParticipant))

	return a[0], nil
}

func ListChannelParticipants(channelId, accountId int64) ([]*models.ChannelParticipant, error) {

	url := fmt.Sprintf("/channel/%d/participant?accountId=%d", channelId, accountId)
	res, err := sendRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}
	var participants []*models.ChannelParticipant
	err = json.Unmarshal(res, &participants)
	if err != nil {
		return nil, err
	}

	return participants, nil
}

func DeleteChannelParticipant(channelId int64, requesterId, accountId int64) (*models.ChannelParticipant, error) {
	c := models.NewChannelParticipant()
	c.AccountId = accountId

	res := make([]*models.ChannelParticipant, 1)
	res[0] = c
	url := fmt.Sprintf("/channel/%d/participant/delete?accountId=%d", channelId, requesterId)
	cps, err := sendModel("POST", url, &res)
	if err != nil {
		return nil, err
	}

	a := *(cps.(*[]*models.ChannelParticipant))
	return a[0], nil
}
