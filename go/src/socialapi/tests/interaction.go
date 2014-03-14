package main

import (
	"encoding/json"
	"fmt"
	"socialapi/models"
)

func testInteractionOperations() {
	post, err := createPost()
	if err != nil {
		fmt.Println("error while creating post", err)
		err = nil
	}

	accountId := post.AccountId
	err = addInteraction("like", post.Id, accountId)
	if err != nil {
		fmt.Println("error while creating interaction", err)
		err = nil
	}

	err = addInteraction("like", post.Id, accountId)
	if err == nil {
		fmt.Println("this should fail, no need :) for duplicate likes", err)
	}

	likes, err := getInteractions("like", post.Id)
	if err != nil {
		fmt.Println("error while getting the likes", err)
		err = nil
	}
	if len(likes) != 2 {
		fmt.Println("like count is wrong", likes)
	}

	err = deleteInteraction("like", post.Id, accountId)
	if err != nil {
		fmt.Println("error while deleting the interaction", err)
		err = nil
	}

	// _, err = getInteractions("like", post.Id)
	// if err == nil {
	// 	fmt.Println("there should be an error while getting the like")
	// }

	for i := 0; i < 10; i++ {
		err := addInteraction("like", post.Id, accountId)
		if err != nil {
			fmt.Println("error while creating post", err)
			err = nil
		}
	}
}

func getInteractions(interactionType string, postId int64) ([]int64, error) {
	url := fmt.Sprintf("/message/%d/interaction/%s", postId, interactionType)
	res, err := sendRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	var interactions []int64
	err = json.Unmarshal(res, &interactions)
	if err != nil {
		return nil, err
	}

	return interactions, nil
}

func addInteraction(interactionType string, postId, accountId int64) error {
	cm := models.NewInteraction()
	cm.AccountId = accountId
	cm.MessageId = postId

	url := fmt.Sprintf("/message/%d/interaction/%s/add", postId, interactionType)
	_, err := sendModel("POST", url, cm)
	if err != nil {
		return err
	}
	return nil
}

func deleteInteraction(interactionType string, postId, accountId int64) error {
	cm := models.NewInteraction()
	cm.AccountId = accountId
	cm.MessageId = postId

	url := fmt.Sprintf("/message/%d/interaction/%s/delete", postId, interactionType)
	_, err := marshallAndSendRequest("POST", url, cm)
	if err != nil {
		return err
	}
	return nil
}
