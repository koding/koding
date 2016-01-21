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

func FetchAccountActivities(accId int64, token string) ([]*models.ChannelMessageContainer, error) {
	url := fmt.Sprintf("/account/%d/posts", accId)

	res, err := sendRequestWithAuth("GET", url, nil, token)
	if err != nil {
		return make([]*models.ChannelMessageContainer, 0), err
	}

	var arr []*models.ChannelMessageContainer

	if err := json.Unmarshal(res, &arr); err != nil {
		return make([]*models.ChannelMessageContainer, 0), err
	}

	return arr, nil
}

func FetchAccountActivityCount(accId int64, token string) (*models.CountResponse, error) {
	url := fmt.Sprintf("/account/%d/posts/count", accId)

	res, err := sendRequestWithAuth("GET", url, nil, token)
	if err != nil {
		return new(models.CountResponse), err
	}

	var cr *models.CountResponse
	if err := json.Unmarshal(res, &cr); err != nil {
		return new(models.CountResponse), err
	}

	return cr, nil
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
