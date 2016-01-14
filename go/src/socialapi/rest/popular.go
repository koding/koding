package rest

import (
	"encoding/json"
	"fmt"
	"socialapi/models"
)

func FetchPopularTopics(token string) ([]*models.ChannelContainer, error) {
	url := fmt.Sprintf("/popular/topics/weekly")
	res, err := sendRequestWithAuth("GET", url, nil, token)
	if err != nil {
		return nil, err
	}

	var channels []*models.ChannelContainer
	err = json.Unmarshal(res, &channels)
	if err != nil {
		return nil, err
	}

	return channels, nil
}
