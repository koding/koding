package rest

import (
	"encoding/json"
	"fmt"
	"socialapi/models"
)

func CreatePost(channelId, accountId int64) (*models.ChannelMessage, error) {
	return CreatePostWithBody(channelId, accountId, "create a message")
}

func CreatePostWithBody(channelId, accountId int64, body string) (*models.ChannelMessage, error) {
	cm := models.NewChannelMessage()
	cm.Body = body
	cm.AccountId = accountId

	return createPostRequest(channelId, cm)
}

func GetPost(id int64, accountId int64, groupName string) (*models.ChannelMessage, error) {
	url := fmt.Sprintf("/message/%d?accountId=%d&groupName=%s", id, accountId, groupName)
	cm := models.NewChannelMessage()
	cmI, err := sendModel("GET", url, cm)
	if err != nil {
		return nil, err
	}
	return cmI.(*models.ChannelMessage), nil
}

func DeletePost(id int64, accountId int64, groupName string) error {
	url := fmt.Sprintf("/message/%d?accountId=%d&groupName=%s", id, accountId, groupName)
	_, err := sendRequest("DELETE", url, nil)
	return err
}

func UpdatePost(cm *models.ChannelMessage) (*models.ChannelMessage, error) {
	cm.Body = "after update"

	url := fmt.Sprintf("/message/%d", cm.Id)
	cmI, err := sendModel("POST", url, cm)
	if err != nil {
		return nil, err
	}

	return cmI.(*models.ChannelMessage), nil
}

type PayloadRequest struct {
	Body      string                 `json:"body"`
	AccountId int64                  `json:"accountId,string"`
	Payload   map[string]interface{} `json:"payload"`
}

func CreatePostWithPayload(channelId, accountId int64, payload map[string]interface{}) (*models.ChannelMessage, error) {
	pr := PayloadRequest{}
	pr.Body = "message with payload"
	pr.AccountId = accountId
	pr.Payload = payload

	return createPostRequest(channelId, pr)
}

func createPostRequest(channelId int64, model interface{}) (*models.ChannelMessage, error) {
	url := fmt.Sprintf("/channel/%d/message", channelId)
	res, err := marshallAndSendRequest("POST", url, model)
	if err != nil {
		return nil, err
	}

	container := models.NewChannelMessageContainer()
	err = json.Unmarshal(res, container)
	if err != nil {
		return nil, err
	}

	return container.Message, nil
}
