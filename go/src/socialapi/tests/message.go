package main

import (
	"fmt"
	"socialapi/models"
)

func testMessageOperations() {
	post, err := createPost(CHANNEL_ID, ACCOUNT_ID)
	if err != nil {
		fmt.Println("error while creating post", err)
		err = nil
	}
	_, err = updatePost(post)
	if err != nil {
		fmt.Println("error while creating post", err)
		err = nil
	}

	post2, err := getPost(post.Id)
	if err != nil {
		fmt.Println("error while getting the post", err)
		err = nil
	}

	if post2.CreatedAt.Second() != post.CreatedAt.Second() {
		fmt.Println("post created ats are not same")
	}

	err = deletePost(post.Id)
	if err != nil {
		fmt.Println("error while deleting the post", err)
		err = nil
	}

	_, err = getPost(post.Id)
	if err == nil {
		fmt.Println("there should be an error while getting the post")
	}

	for i := 0; i < 10; i++ {
		_, err := createPost(CHANNEL_ID, ACCOUNT_ID)
		if err != nil {
			fmt.Println("error while creating post", err)
			err = nil
		}
	}
}

func createPost(channelId, accountId int64) (*models.ChannelMessage, error) {
	cm := models.NewChannelMessage()
	cm.Body = "create a message"
	cm.AccountId = accountId

	url := fmt.Sprintf("/channel/%d/message", channelId)
	cmI, err := sendModel("POST", url, cm)
	if err != nil {
		return nil, err
	}
	return cmI.(*models.ChannelMessage), nil
}

func updatePost(cm *models.ChannelMessage) (*models.ChannelMessage, error) {
	cm.Body = "after update"

	url := fmt.Sprintf("/message/%d", cm.Id)
	cmI, err := sendModel("POST", url, cm)
	if err != nil {
		return nil, err
	}

	return cmI.(*models.ChannelMessage), nil
}

func getPost(id int64) (*models.ChannelMessage, error) {

	url := fmt.Sprintf("/message/%d", id)
	cm := models.NewChannelMessage()
	cmI, err := sendModel("GET", url, cm)
	if err != nil {
		return nil, err
	}
	return cmI.(*models.ChannelMessage), nil
}

func deletePost(id int64) error {
	url := fmt.Sprintf("/message/%d", id)
	_, err := sendRequest("DELETE", url, nil)
	return err
}
