package rest

import (
	"encoding/json"
	"fmt"
	kodingmodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
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

func CreateAccountWithDailyDigest() (*models.Account, error) {
	acc, err := models.CreateAccountInBothDbs()
	if err != nil {
		return nil, err
	}

	eFreq := kodingmodels.EmailFrequency{
		Global:  true,
		Daily:   true,
		Comment: true,
	}

	err = modelhelper.UpdateEmailFrequency(acc.OldId, eFreq)
	if err != nil {
		return nil, err
	}

	return acc, nil
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

func CheckPostOwnership(acc *models.Account, post *models.ChannelMessage) (bool, error) {
	return sendOwnershipRequest(acc.Id, &request.Query{
		ObjectId: post.Id,
		Type:     "channel-message",
	})
}

func CheckChannelOwnership(acc *models.Account, channel *models.Channel) (bool, error) {
	return sendOwnershipRequest(acc.Id, &request.Query{
		ObjectId: channel.Id,
		Type:     "channel",
	})
}
