package rest

import (
	"encoding/json"
	"fmt"
	"net/http"
	"socialapi/models"
)

func CreatePost(channelId int64, token string) (*models.ChannelMessage, error) {
	return CreatePostWithBodyAndAuth(channelId, "create a message", token)
}

func CreatePostWithBodyAndAuth(channelId int64, body, token string) (*models.ChannelMessage, error) {
	url := fmt.Sprintf("/channel/%d/message", channelId)
	cm := models.NewChannelMessage()
	cm.Body = body
	res, err := marshallAndSendRequestWithAuth("POST", url, cm, token)
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

func CreatePostWithBody(channelId, accountId int64, body string) (*models.ChannelMessage, error) {
	cm := models.NewChannelMessage()
	cm.Body = body
	cm.AccountId = accountId

	return createPostRequest(channelId, cm, http.Header{})
}

func CreatePostWithHeader(channelId int64, header http.Header, token string) (*models.ChannelMessage, error) {
	cm := models.NewChannelMessage()
	cm.Body = "Text1Text2"

	return createPostRequestWithAuth(channelId, cm, header, token)
}

func GetPost(id int64, token string) (*models.ChannelMessage, error) {
	url := fmt.Sprintf("/message/%d", id)
	cm := models.NewChannelMessage()
	cmI, err := sendModelWithAuth("GET", url, cm, token)
	if err != nil {
		return nil, err
	}
	return cmI.(*models.ChannelMessage), nil
}

func GetPostBySlug(slug string, accountId int64) (*models.ChannelMessageContainer, error) {
	url := fmt.Sprintf("/message/slug/%s?accountId=%d", slug, accountId)
	cmc := models.NewChannelMessageContainer()
	cmI, err := sendModel("GET", url, cmc)
	if err != nil {
		return nil, err
	}
	return cmI.(*models.ChannelMessageContainer), nil
}

func DeletePost(id int64, token string) error {
	url := fmt.Sprintf("/message/%d", id)
	_, err := sendRequestWithAuth("DELETE", url, nil, token)
	return err
}

func UpdatePost(cm *models.ChannelMessage, token string) (*models.ChannelMessage, error) {
	cm.Body = "after update"

	url := fmt.Sprintf("/message/%d", cm.Id)
	cmI, err := sendModelWithAuth("POST", url, cm, token)
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

func CreatePostWithPayload(channelId int64, payload map[string]interface{}, token string) (*models.ChannelMessage, error) {
	pr := PayloadRequest{}
	pr.Body = "message with payload"
	pr.Payload = payload

	return createPostRequestWithAuth(channelId, pr, http.Header{}, token)
}

func createPostRequest(channelId int64, model interface{}, h http.Header) (*models.ChannelMessage, error) {
	url := fmt.Sprintf("/channel/%d/message", channelId)
	res, err := marshallAndSendRequestWithHeader("POST", url, model, h)
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

func createPostRequestWithAuth(channelId int64, model interface{}, h http.Header, token string) (*models.ChannelMessage, error) {
	url := fmt.Sprintf("/channel/%d/message", channelId)
	res, err := marshallAndSendRequestWithHeaderAndAuth("POST", url, model, h, token)
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
