package rest

import (
	"encoding/json"
	"fmt"
	"socialapi/models"
	"socialapi/request"

	"github.com/google/go-querystring/query"
)

func SendPrivateChannelRequest(pmr models.ChannelRequest, token string) (*models.ChannelContainer, error) {
	url := "/privatechannel/init"
	res, err := marshallAndSendRequestWithAuth("POST", url, pmr, token)
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

func GetPrivateChannels(q *request.Query, token string) ([]models.ChannelContainer, error) {
	return fetchPrivateChannels(q, "/privatechannel/list", token)
}

func SearchPrivateChannels(q *request.Query, token string) ([]models.ChannelContainer, error) {
	return fetchPrivateChannels(q, "/privatechannel/search", token)
}

func fetchPrivateChannels(q *request.Query, endpoint, token string) ([]models.ChannelContainer, error) {
	v, err := query.Values(q)
	if err != nil {
		return nil, err
	}

	url := fmt.Sprintf("%s?%s", endpoint, v.Encode())
	res, err := sendRequestWithAuth("GET", url, nil, token)
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
