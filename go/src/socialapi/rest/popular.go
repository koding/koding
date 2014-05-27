package rest

import (
	"encoding/json"
	"fmt"
	"socialapi/models"
)

func FetchPopularTopics(accountId int64, groupName string) ([]*models.ChannelContainer, error) {
	url := fmt.Sprintf("/popular/topics/weekly?accountId=%d&groupName=%s", accountId, groupName)
	res, err := sendRequest("GET", url, nil)
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
