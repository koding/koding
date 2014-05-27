package rest

import (
	"encoding/json"
	"fmt"
	"socialapi/models"
)

func FetchFollowedChannels(accountId int64, groupName string) ([]*models.ChannelContainer, error) {
	url := fmt.Sprintf("/account/%d/channels?accountId=%d&groupName=%s", accountId, accountId, groupName)
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
