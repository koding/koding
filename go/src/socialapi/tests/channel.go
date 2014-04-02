package main

import (
	"fmt"
	"math/rand"
	"socialapi/models"
	"strconv"
	"time"
)

func testChannelOperations() {
	channel, err := createChannel()
	if err != nil {
		fmt.Println("error while creating channel", err)
		err = nil
	}

	_, err = updateChannel(channel)
	if err != nil {
		fmt.Println("error while creating channel", err)
		err = nil
	}

	channel2, err := getChannel(channel.Id)
	if err != nil {
		fmt.Println("error while getting the channel", err)
		err = nil
	}

	if channel2.CreatedAt.Second() != channel.CreatedAt.Second() {
		fmt.Println("channel created ats are not same")
	}

	err = deleteChannel(channel.Id)
	if err != nil {
		fmt.Println("error while deleting the channel", err)
		err = nil
	}

	_, err = getChannel(channel.Id)
	if err == nil {
		fmt.Println("there should be an error while getting the channel")
	}

	for i := 0; i < 10; i++ {
		_, err := createChannel()
		if err != nil {
			fmt.Println("error while creating channel", err)
			err = nil
		}
	}

	testChannelParticipantOperations(channel2)
}

func createChannel() (*models.Channel, error) {
	c := models.NewChannel()
	rand.Seed(time.Now().UnixNano())
	c.GroupName = c.GroupName + strconv.Itoa(rand.Intn(100000000))
	c.Name = c.Name + strconv.Itoa(rand.Intn(100000000))
	cmI, err := sendModel("POST", "/channel", c)
	if err != nil {
		return nil, err
	}
	return cmI.(*models.Channel), nil
}

func updateChannel(cm *models.Channel) (*models.Channel, error) {
	url := fmt.Sprintf("/channel/%d", cm.Id)
	cmI, err := sendModel("POST", url, cm)
	if err != nil {
		return nil, err
	}

	return cmI.(*models.Channel), nil
}

func getChannel(id int64) (*models.Channel, error) {

	url := fmt.Sprintf("/channel/%d", id)
	cm := models.NewChannel()
	cmI, err := sendModel("GET", url, cm)
	if err != nil {
		return nil, err
	}
	return cmI.(*models.Channel), nil
}

func deleteChannel(id int64) error {
	url := fmt.Sprintf("/channel/%d", id)
	_, err := sendRequest("DELETE", url, nil)
	return err
}
