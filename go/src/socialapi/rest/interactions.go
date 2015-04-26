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

func AddInteraction(iType string, postId, accountId int64) (*models.Interaction, error) {
	cm := models.NewInteraction()
	cm.AccountId = accountId
	cm.MessageId = postId

	url := fmt.Sprintf("/message/%d/interaction/%s/add", postId, iType)
	_, err := sendModel("POST", url, cm)
	if err != nil {
		return cm, err
	}

	return cm, nil
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

func ListInteractedMesssagesInteraction(iType string, accountId int64, token string) ([]*models.ChannelMessageContainer, error) {
	url := fmt.Sprintf("/account/%d/interaction/%s", accountId, iType)

	res, err := sendRequestWithAuth("GET", url, nil, token)
	if err != nil {
		return nil, err
	}

	// var cm []*models.ChannelMessageContainer
	cm := make([]*models.ChannelMessageContainer, 0)
	err = json.Unmarshal(res, &cm)
	if err != nil {
		return nil, err
	}

	return cm, nil
}
