package main

import (
	"encoding/json"
	"fmt"
	"socialapi/models"
)

func testReplyOperations() {
	post, err := createPost(CHANNEL_ID, ACCOUNT_ID)
	if err != nil {
		fmt.Println("error while creating post", err)
		err = nil
	}

	accountId := post.AccountId

	for i := 0; i < 2; i++ {
		_, err = addReply(post.Id, accountId)
		if err != nil {
			fmt.Println("error while creating interaction", err)
			err = nil
		}
	}

	replies, err := getReplies(post.Id)
	if err != nil {
		fmt.Println("error while getting the replies", err)
		err = nil
	}

	if len(replies) != 2 {
		fmt.Println("post count is wrong", replies)
	}

	err = deleteReply(post.Id, replies[0].Id)
	if err != nil {
		fmt.Println("error while deleting the interaction", err)
		err = nil
	}

	replies, err = getReplies(post.Id)
	if err != nil {
		fmt.Println("error while getting the replies", err)
		err = nil
	}

	if len(replies) != 1 {
		fmt.Println("post count is wrong", replies)
	}

}

func getReplies(postId int64) ([]*models.ChannelMessage, error) {
	url := fmt.Sprintf("/message/%d/reply", postId)
	res, err := sendRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	var replies []*models.ChannelMessage
	err = json.Unmarshal(res, &replies)
	if err != nil {
		return nil, err
	}

	return replies, nil
}

func addReply(postId, accountId int64) (*models.ChannelMessage, error) {
	cm := models.NewChannelMessage()
	cm.Body = "reply body"
	cm.AccountId = accountId

	url := fmt.Sprintf("/message/%d/reply", postId)
	_, err := sendModel("POST", url, cm)
	if err != nil {
		return nil, err
	}
	return cm, nil
}

func deleteReply(postId, replyId int64) error {
	url := fmt.Sprintf("/message/%d/reply/%d", postId, replyId)
	_, err := sendRequest("DELETE", url, nil)
	if err != nil {
		return err
	}
	return nil
}
