package rest

import (
	"encoding/json"
	"fmt"
	"socialapi/models"
	"socialapi/request"

	"github.com/google/go-querystring/query"
)

func CreateAccount(a *models.Account) (*models.Account, error) {
	a.Nick = a.OldId
	acc, err := sendModel("POST", "/account", a)
	if err != nil {
		return nil, err
	}

	return acc.(*models.Account), nil
}

func sendOwnershipRequest(accountId int64, q *request.Query) (bool, error) {
	v, err := query.Values(q)
	if err != nil {
		return false, err
	}

	url := fmt.Sprintf("/account/%d/owns?%s", accountId, v.Encode())
	res, err := sendRequest("GET", url, nil)
	if err != nil {
		return false, err
	}

	var response struct{ Success bool }

	if err := json.Unmarshal(res, &response); err != nil {
		return false, err
	}

	return response.Success, nil

}

func CheckChannelOwnership(acc *models.Account, channel *models.Channel) (bool, error) {
	return sendOwnershipRequest(acc.Id, &request.Query{
		ObjectId: channel.Id,
		Type:     "channel",
	})
}

func FetchAccountChannels(token string) (*models.ChannelContainers, error) {
	cc := models.NewChannelContainers()
	res, err := marshallAndSendRequestWithAuth("GET", "/account/channels", cc, token)
	if err != nil {
		return nil, err
	}

	if err := json.Unmarshal(res, cc); err != nil {
		return nil, err
	}

	return cc, nil
}
