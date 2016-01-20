package rest

import (
	"encoding/json"
	"fmt"
	"socialapi/models"

	"gopkg.in/mgo.v2/bson"
)

func CreateChannelParticipants(channelId int64, token string, c int) ([]*models.ChannelParticipant, error) {
	var participants []*models.ChannelParticipant
	for i := 0; i < c; i++ {
		participant, err := CreateChannelParticipant(channelId, token)
		if err != nil {
			return nil, err
		}

		participants = append(participants, participant)
	}

	return participants, nil
}

func CreateChannelParticipant(channelId int64, token string) (*models.ChannelParticipant, error) {
	account := models.NewAccount()
	account.OldId = bson.NewObjectId().Hex()
	account, _ = CreateAccount(account)
	return AddChannelParticipant(channelId, token, account.Id)
}

func ListChannelParticipants(channelId int64, token string) ([]models.ChannelParticipantContainer, error) {
	url := fmt.Sprintf("/channel/%d/participants", channelId)

	res, err := sendRequestWithAuth("GET", url, nil, token)
	if err != nil {
		return nil, err
	}
	var participants []models.ChannelParticipantContainer
	err = json.Unmarshal(res, &participants)
	if err != nil {
		return nil, err
	}

	return participants, nil
}

func AddChannelParticipant(channelId int64, token string, accountIds ...int64) (*models.ChannelParticipant, error) {
	url := fmt.Sprintf("/channel/%d/participants/add", channelId)
	return channelParticipantOp(
		url,
		channelId,
		token,
		accountIds...,
	)
}

func DeleteChannelParticipant(channelId int64, token string, accountIds ...int64) (*models.ChannelParticipant, error) {
	url := fmt.Sprintf("/channel/%d/participants/remove", channelId)
	return channelParticipantOp(
		url,
		channelId,
		token,
		accountIds...,
	)
}

func BlockChannelParticipant(channelId int64, token string, accountIds ...int64) (*models.ChannelParticipant, error) {
	url := fmt.Sprintf("/channel/%d/participants/block", channelId)
	return channelParticipantOp(
		url,
		channelId,
		token,
		accountIds...,
	)
}

func UnblockChannelParticipant(channelId int64, token string, accountIds ...int64) (*models.ChannelParticipant, error) {
	url := fmt.Sprintf("/channel/%d/participants/unblock", channelId)
	return channelParticipantOp(
		url,
		channelId,
		token,
		accountIds...,
	)
}

func AcceptInvitation(channelId int64, token string) error {
	url := fmt.Sprintf("/channel/%d/invitation/accept", channelId)
	cp := models.NewChannelParticipant()
	_, err := marshallAndSendRequestWithAuth("POST", url, cp, token)

	return err
}

func RejectInvitation(channelId int64, token string) error {
	url := fmt.Sprintf("/channel/%d/invitation/reject", channelId)
	cp := models.NewChannelParticipant()
	_, err := marshallAndSendRequestWithAuth("POST", url, cp, token)

	return err
}

func InviteChannelParticipant(channelId int64, token string, accountIds ...int64) (*models.ChannelParticipant, error) {
	url := fmt.Sprintf("/channel/%d/participants/add", channelId)

	res := make([]*models.ChannelParticipant, 0)
	for _, accountId := range accountIds {
		c := models.NewChannelParticipant()
		c.AccountId = accountId
		c.StatusConstant = models.ChannelParticipant_STATUS_REQUEST_PENDING
		res = append(res, c)
	}

	cps, err := sendModelWithAuth("POST", url, &res, token)
	if err != nil {
		return nil, err
	}

	a := *(cps.(*[]*models.ChannelParticipant))

	return a[0], nil
}

func channelParticipantOp(url string, channelId int64, token string, accountIds ...int64) (*models.ChannelParticipant, error) {

	res := make([]*models.ChannelParticipant, 0)
	for _, accountId := range accountIds {
		c := models.NewChannelParticipant()
		c.AccountId = accountId
		res = append(res, c)
	}

	cps, err := sendModelWithAuth("POST", url, &res, token)
	if err != nil {
		return nil, err
	}

	a := *(cps.(*[]*models.ChannelParticipant))

	return a[0], nil
}
