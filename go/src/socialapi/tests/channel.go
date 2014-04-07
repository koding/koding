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

	testChannelParticipantOperations(channel)
}

func createChannel() (*models.Channel, error) {
	c := models.NewChannel()
	rand.Seed(time.Now().UnixNano())
	groupName := c.GroupName + strconv.Itoa(rand.Intn(100000000))

	return createChannelByGroupNameAndType(rand.Int63(), groupName, c.TypeConstant)
}

func createChannelByGroupNameAndType(creatorId int64, groupName, typeConstant string) (*models.Channel, error) {
	c := models.NewChannel()
	c.GroupName = groupName
	c.CreatorId = creatorId
	c.TypeConstant = typeConstant
	c.Name = c.Name + strconv.Itoa(rand.Intn(100000000))
	cm, err := sendModel("POST", "/channel", c)
	if err != nil {
		return nil, err
	}
	return cm.(*models.Channel), nil
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
