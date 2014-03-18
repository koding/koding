package main

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"socialapi/models"
)

func testChannelParticipantOperations(channel *models.Channel) {
	fmt.Println("creating participants with channel id", channel.Id)
	var channelParticipant *models.ChannelParticipant
	var err error

	for i := 0; i < 3; i++ {
		channelParticipant, err = createChannelParticipant(channel.Id)
		if err != nil {
			fmt.Println("error while creating channelParticipant 1", err)
			err = nil
			return
		}
	}

	channelParticipants, err := getChannelParticipants(channel.Id)
	if err != nil {
		fmt.Println("error while getting the channelParticipants", err)
		err = nil
	}

	if len(channelParticipants) == 0 {
		fmt.Println("channel participants len should be more than 1")
		return
	}

	if channelParticipants[len(channelParticipants)-1].CreatedAt.Second() != channelParticipant.CreatedAt.Second() {
		fmt.Println("channelParticipant created ats are not same")
		fmt.Println(channelParticipant)
		fmt.Println(channelParticipants[0])

	}

	err = deleteChannelParticipant(channel.Id, channelParticipant)
	if err != nil {
		fmt.Println("error while deleting the channelParticipant", err)
		err = nil
	}

	channelParticipants, err = getChannelParticipants(channel.Id)
	if err != nil {
		fmt.Println("error while getting the channelParticipants", err)
		err = nil
	}

	if len(channelParticipants) != 2 {
		fmt.Println("there shouldnt be more than one participants in this channel")
		return
	}

	for i := 0; i < 10; i++ {
		_, err := createChannelParticipant(channel.Id)
		if err != nil {
			fmt.Println("error while creating channelParticipant 2", err)
			err = nil
		}
	}

}

func createChannelParticipant(channelId int64) (*models.ChannelParticipant, error) {
	return addChannelParticipant(channelId, rand.Int63())
}

func addChannelParticipant(channelId, accountId int64) (*models.ChannelParticipant, error) {
	c := models.NewChannelParticipant()
	c.AccountId = accountId

	url := fmt.Sprintf("/channel/%d/participant/%d", channelId, c.AccountId)
	cmI, err := sendModel("POST", url, c)
	if err != nil {
		return nil, err
	}
	return cmI.(*models.ChannelParticipant), nil
}

func getChannelParticipants(channelId int64) ([]*models.ChannelParticipant, error) {

	url := fmt.Sprintf("/channel/%d/participant", channelId)
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

func deleteChannelParticipant(channelId int64, data *models.ChannelParticipant) error {
	data.Status = models.ChannelParticipant_STATUS_LEFT
	url := fmt.Sprintf("/channel/%d/participant/%d", channelId, data.AccountId)
	_, err := sendRequest("DELETE", url, nil)
	return err
}
