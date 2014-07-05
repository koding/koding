package rest

import (
	"encoding/json"
	"fmt"
	"socialapi/models"

	"labix.org/v2/mgo/bson"
)

func CreateChannelParticipants(channelId, accountId int64, c int) ([]*models.ChannelParticipant, error) {
	var participants []*models.ChannelParticipant
	for i := 0; i < c; i++ {
		participant, err := CreateChannelParticipant(channelId, accountId)
		if err != nil {
			return nil, err
		}

		participants = append(participants, participant)
	}

	return participants, nil
}

func CreateChannelParticipant(channelId, accountId int64) (*models.ChannelParticipant, error) {
	account := models.NewAccount()
	account.OldId = bson.NewObjectId().Hex()
	account, _ = CreateAccount(account)
	return AddChannelParticipant(channelId, accountId, account.Id)
}

func ListChannelParticipants(channelId, accountId int64) ([]*models.ChannelParticipant, error) {

	url := fmt.Sprintf("/channel/%d/participants?accountId=%d", channelId, accountId)
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

func AddChannelParticipant(channelId, requesterId, accountId int64) (*models.ChannelParticipant, error) {
	c := models.NewChannelParticipant()
	c.AccountId = accountId

	res := []*models.ChannelParticipant{c}

	url := fmt.Sprintf("/channel/%d/participants/add?accountId=%d", channelId, requesterId)
	cps, err := sendModel("POST", url, &res)
	if err != nil {
		return nil, err
	}

	a := *(cps.(*[]*models.ChannelParticipant))

	return a[0], nil
}

func DeleteChannelParticipant(channelId int64, requesterId, accountId int64) (*models.ChannelParticipant, error) {
	c := models.NewChannelParticipant()
	c.AccountId = accountId

	res := []*models.ChannelParticipant{c}

	url := fmt.Sprintf("/channel/%d/participants/remove?accountId=%d", channelId, requesterId)
	cps, err := sendModel("POST", url, &res)
	if err != nil {
		return nil, err
	}

	a := *(cps.(*[]*models.ChannelParticipant))
	return a[0], nil
}
