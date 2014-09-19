package rest

import (
	"encoding/json"
	"fmt"
	"socialapi/models"
	"socialapi/request"

	"github.com/google/go-querystring/query"
)

func SendPrivateMessage(pmr models.PrivateMessageRequest) (*models.ChannelContainer, error) {

	url := "/privatemessage/init"
	res, err := marshallAndSendRequest("POST", url, pmr)
	if err != nil {
		return nil, err
	}

	model := models.NewChannelContainer()
	err = json.Unmarshal(res, model)
	if err != nil {
		return nil, err
	}

	return model, nil
}

func GetPrivateMessages(q *request.Query) ([]models.ChannelContainer, error) {
	return fetchPrivateMessages(q, "/privatemessage/list")
}

func SearchPrivateMessages(q *request.Query) ([]models.ChannelContainer, error) {
	return fetchPrivateMessages(q, "/privatemessage/search")
}

func fetchPrivateMessages(q *request.Query, endpoint string) ([]models.ChannelContainer, error) {
	v, err := query.Values(q)
	if err != nil {
		return nil, err
	}

	url := fmt.Sprintf("%s?%s", endpoint, v.Encode())
	res, err := sendRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	var privateMessages []models.ChannelContainer
	err = json.Unmarshal(res, &privateMessages)
	if err != nil {
		return nil, err
	}

	return privateMessages, nil
}
