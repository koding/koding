package rest

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"net/url"
	"socialapi/models"
	"socialapi/request"
	"strconv"

	"github.com/google/go-querystring/query"
)

func GetHistory(channelId int64, q *request.Query, token string) (*models.HistoryResponse, error) {
	v, err := query.Values(q)
	if err != nil {
		return nil, err
	}

	url := fmt.Sprintf("/channel/%d/history?%s", channelId, v.Encode())
	res, err := sendRequestWithAuth("GET", url, nil, token)
	if err != nil {
		return nil, err
	}

	var history models.HistoryResponse
	err = json.Unmarshal(res, &history)
	if err != nil {
		return nil, err
	}

	return &history, nil
}

func CountHistory(channelId int64) (*models.CountResponse, error) {
	c := models.NewChannelMessageList()
	c.ChannelId = channelId

	url := fmt.Sprintf("/channel/%d/history/count", channelId)
	res, err := marshallAndSendRequest("GET", url, c)
	if err != nil {
		return nil, err
	}

	var count models.CountResponse
	err = json.Unmarshal(res, &count)
	if err != nil {
		return nil, err
	}

	return &count, nil
}

func FetchChannelsByQuery(accountId int64, q *request.Query, token string) ([]*models.Channel, error) {
	v, err := query.Values(q)
	if err != nil {
		return nil, err
	}

	url := fmt.Sprintf("/account/%d/channels?%s", accountId, v.Encode())
	res, err := sendRequestWithAuth("GET", url, nil, token)
	if err != nil {
		return nil, err
	}

	var ccs []*models.ChannelContainer
	err = json.Unmarshal(res, &ccs)
	if err != nil {
		return nil, err
	}

	channels := make([]*models.Channel, len(ccs))
	for i, cc := range ccs {
		channels[i] = cc.Channel
	}

	return channels, nil
}

func FetchChannelByName(accountId int64, name, groupName, typeConstant, token string) (*models.Channel, error) {
	ccs, err := FetchChannelContainerByName(accountId, name, groupName, typeConstant, token)
	if err != nil {
		return nil, err
	}

	return ccs.Channel, nil
}

func FetchChannelContainerByName(accountId int64, name, groupName, typeConstant, token string) (*models.ChannelContainer, error) {
	url := fmt.Sprintf("/channel/name/%s?groupName=%s&type=%s&accountId=%d", name, groupName, typeConstant, accountId)

	res, err := sendRequestWithAuth("GET", url, nil, token)
	if err != nil {
		return nil, err
	}

	ccs := &models.ChannelContainer{}
	err = json.Unmarshal(res, ccs)
	if err != nil {
		return nil, err
	}

	return ccs, nil
}

func FetchChannelsByParticipants(accountIds []int64, typeConstant, token string) ([]models.ChannelContainer, error) {
	v := url.Values{}
	v.Add("type", typeConstant)
	for _, id := range accountIds {
		v.Add("id", fmt.Sprintf("%d", id))
	}

	url := fmt.Sprintf("/channel/by/participants?%s", v.Encode())
	res, err := sendRequestWithAuth("GET", url, nil, token)
	if err != nil {
		return nil, err
	}

	var ccs []models.ChannelContainer
	if err := json.Unmarshal(res, &ccs); err != nil {
		return nil, err
	}

	return ccs, nil
}

func DeleteChannel(creatorId, channelId int64) error {
	c := models.NewChannel()
	c.CreatorId = creatorId
	c.Id = channelId

	url := fmt.Sprintf("/channel/%d/delete", channelId)
	_, err := sendModel("POST", url, c)
	if err != nil {
		return err
	}
	return nil
}

func CreateChannelByGroupNameAndType(creatorId int64, groupName, typeConstant, token string) (*models.Channel, error) {
	c := models.NewChannel()
	c.GroupName = groupName
	c.CreatorId = creatorId
	c.TypeConstant = typeConstant
	c.PrivacyConstant = models.Channel_PRIVACY_PUBLIC
	c.Name = c.Name + strconv.Itoa(rand.Intn(100000000))
	res, err := marshallAndSendRequestWithAuth("POST", "/channel", c, token)
	if err != nil {
		return nil, err
	}

	cc := models.NewChannelContainer()
	err = json.Unmarshal(res, cc)
	if err != nil {
		return nil, err
	}

	return cc.Channel, nil
}

func UpdateChannel(cm *models.Channel, token string) (*models.Channel, error) {
	url := fmt.Sprintf("/channel/%d/update", cm.Id)

	res, err := marshallAndSendRequestWithAuth("POST", url, cm, token)
	if err != nil {
		return nil, err
	}

	cc := models.NewChannelContainer()
	err = json.Unmarshal(res, cc)
	if err != nil {
		return nil, err
	}

	return cc.Channel, nil
}

func GetChannel(id int64) (*models.Channel, error) {
	cc, err := GetChannelContainer(id)
	if err != nil {
		return nil, err
	}

	return cc.Channel, nil
}

// GetChannelWithToken gets the channel of the account with given account's session data.
func GetChannelWithToken(id int64, token string) (*models.Channel, error) {
	cc, err := GetChannelContainerWithToken(id, token)
	if err != nil {
		return nil, err
	}

	return cc.Channel, nil
}

func GetChannelContainerWithToken(id int64, token string) (*models.ChannelContainer, error) {
	url := fmt.Sprintf("/channel/%d", id)
	cc := models.NewChannelContainer()
	cmI, err := sendModelWithAuth("GET", url, cc, token)
	if err != nil {
		return nil, err
	}

	return cmI.(*models.ChannelContainer), nil
}

func GetChannelContainer(id int64) (*models.ChannelContainer, error) {
	url := fmt.Sprintf("/channel/%d", id)
	cc := models.NewChannelContainer()
	cmI, err := sendModel("GET", url, cc)
	if err != nil {
		return nil, err
	}

	return cmI.(*models.ChannelContainer), nil
}

func SearchChannels(q *request.Query) ([]*models.Channel, error) {
	v, err := query.Values(q)
	if err != nil {
		return nil, err
	}

	url := fmt.Sprintf("/channel/search?%s", v.Encode())
	res, err := sendRequestWithAuth("GET", url, nil, "")
	if err != nil {
		return nil, err
	}

	channels := make([]*models.Channel, 0)
	err = json.Unmarshal(res, &channels)
	if err != nil {
		return nil, err
	}

	return channels, nil
}

func CreateGroupActivityChannel(creatorId int64, groupName string) (*models.Channel, error) {
	c := models.NewChannel()
	c.GroupName = groupName
	c.CreatorId = creatorId
	c.TypeConstant = models.Channel_TYPE_GROUP
	c.Name = groupName

	cm, err := sendModel("POST", "/channel", c)
	if err != nil {
		return nil, err
	}

	return cm.(*models.Channel), nil
}
