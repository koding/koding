package main

import (
	"encoding/json"
	"fmt"
	"socialapi/models"
)

func testChannelParticipantOperations(channel *models.Channel) {
	fmt.Println("creating participants with channel id", channel.Id)
	var channelParticipant *models.ChannelParticipant
	for i := 0; i < 3; i++ {
		channelParticipant, err := createChannelParticipant(channel.Id)
		if err != nil {
			fmt.Println("error while creating channelParticipant 1", err)
			err = nil
			return
		}
		_, err = updateChannelParticipant(channelParticipant)
		if err != nil {
			fmt.Println("error while updating channelParticipant", err)
			err = nil
		}
	}

	channelParticipants, err := getChannelParticipants(channel.Id)
	if err != nil {
		fmt.Println("error while getting the channelParticipants", err)
		err = nil
	}

	fmt.Println(channelParticipants)
	if len(channelParticipants) == 0 {
		fmt.Println("channel participants len should be more than 1")
		return
	}

	fmt.Println("gel beri")
	if channelParticipants[0].CreatedAt.Second() != channelParticipant.CreatedAt.Second() {
		fmt.Println("channelParticipant created ats are not same")
		fmt.Println(channelParticipant)
		fmt.Println(channelParticipants[0])

	}

	fmt.Println("gel beri2")
	err = deleteChannelParticipant(channel.Id, channelParticipant)
	if err != nil {
		fmt.Println("error while deleting the channelParticipant", err)
		err = nil
	}

	fmt.Println("gel beri3")

	channelParticipants, err = getChannelParticipants(channel.Id)
	if err != nil {
		fmt.Println("error while getting the channelParticipants", err)
		err = nil
	}

	fmt.Println("gel beri 4")

	if len(channelParticipants) != 0 {
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
	c := models.NewChannelParticipant()
	c.AccountId = ACCOUNT_ID

	url := fmt.Sprintf("/channel/%d/participant", channelId)
	cmI, err := sendModel("POST", url, c)
	if err != nil {
		return nil, err
	}
	return cmI.(*models.ChannelParticipant), nil
}

func updateChannelParticipant(cm *models.ChannelParticipant) (*models.ChannelParticipant, error) {
	url := fmt.Sprintf("/channel/%d/participant", cm.Id)
	cmI, err := sendModel("POST", url, cm)
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
	fmt.Println(res)

	var participants []*models.ChannelParticipant
	err = json.Unmarshal(res, &participants)
	if err != nil {
		return nil, err
	}

	return participants, nil
}

func deleteChannelParticipant(channelId int64, data *models.ChannelParticipant) error {
	url := fmt.Sprintf("/channel/%d/participant", channelId)
	dataByte, err := json.Marshal(data)
	if err != nil {
		return err
	}

	_, err = sendRequest("POST", url, dataByte)
	return err
}
