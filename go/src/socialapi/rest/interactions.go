package rest

import (
	"encoding/json"
	"fmt"
	"socialapi/models"
)

func GetInteractions(interactionType string, postId int64) ([]string, error) {
	url := fmt.Sprintf("/message/%d/interaction/%s", postId, interactionType)
	res, err := sendRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	var interactions []string
	err = json.Unmarshal(res, &interactions)
	if err != nil {
		return nil, err
	}

	return interactions, nil
}

func AddInteraction(interactionType string, postId, accountId int64) error {
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

func DeleteInteraction(interactionType string, postId, accountId int64) error {
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
