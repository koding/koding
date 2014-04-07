package main

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"socialapi/models"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelParticipantOperations(t *testing.T) {
	Convey("while testing channel participants", t, func() {

		Convey("first we should be able to create dummy channel", func() {

			Convey("anyone can add user to it", nil)

			Convey("creator can remove any account", nil)

			Convey("creator can not do self-remove", nil)

			Convey("account can remove itself", nil)

			Convey("3rd user can not remove any other account", nil)

			Convey("do not allow duplicate participation", nil)

		})

	})
}

func createChannelParticipant(channelId int64) (*models.ChannelParticipant, error) {
	return addChannelParticipant(channelId, rand.Int63(), rand.Int63())
}

func addChannelParticipant(channelId, requesterId, accountId int64) (*models.ChannelParticipant, error) {
	c := models.NewChannelParticipant()
	c.AccountId = requesterId

	url := fmt.Sprintf("/channel/%d/participant/%d/add", channelId, accountId)
	cmI, err := sendModel("POST", url, c)
	if err != nil {
		return nil, err
	}
	return cmI.(*models.ChannelParticipant), nil
}

func listChannelParticipants(channelId, accountId int64) ([]*models.ChannelParticipant, error) {

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

func deleteChannelParticipant(channelId int64, requesterId, accountId int64) (*models.ChannelParticipant, error) {
	c := models.NewChannelParticipant()
	c.AccountId = requesterId

	url := fmt.Sprintf("/channel/%d/participant/%d/delete", channelId, accountId)
	cmI, err := sendModel("POST", url, c)
	if err != nil {
		return nil, err
	}
	return cmI.(*models.ChannelParticipant), nil
}
