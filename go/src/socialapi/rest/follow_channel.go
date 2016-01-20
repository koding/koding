package rest

import (
	"encoding/json"
	"fmt"
	"socialapi/models"
)

func FetchFollowedChannels(accountId int64, token string) ([]*models.ChannelContainer, error) {
	url := fmt.Sprintf("/account/%d/channels", accountId)

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
