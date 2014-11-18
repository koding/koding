package rest

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"socialapi/models"
	"socialapi/request"
	"strconv"
	"time"

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

func FetchChannels(accountId int64) ([]*models.Channel, error) {
	url := fmt.Sprintf("/account/%d/channels", accountId)
	res, err := sendRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	var channels []*models.Channel
	err = json.Unmarshal(res, &channels)
	if err != nil {
		return nil, err
	}

	return channels, nil
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

func CreateChannel(creatorId int64) (*models.Channel, error) {
	return CreateChannelWithType(creatorId, models.Channel_TYPE_DEFAULT)
}

func CreateChannelWithType(creatorId int64, typeConstant string) (*models.Channel, error) {
	c := buildChannelWithRandomGroup(creatorId)
	c.TypeConstant = typeConstant

	return CreateChannelByGroupNameAndType(creatorId, c.GroupName, typeConstant)
}

// buildChannelWithRandomGroup creates a channel with group name "koding[randonnumber]"
func buildChannelWithRandomGroup(creatorId int64) *models.Channel {
	c := models.NewChannel()
	rand.Seed(time.Now().UnixNano())
	c.GroupName = c.GroupName + strconv.Itoa(rand.Intn(100000000))

	return c
}

func CreateChannelByGroupNameAndType(creatorId int64, groupName, typeConstant string) (*models.Channel, error) {
	c := models.NewChannel()
	c.GroupName = groupName
	c.CreatorId = creatorId
	c.TypeConstant = typeConstant
	c.PrivacyConstant = models.Channel_PRIVACY_PUBLIC
	c.Name = c.Name + strconv.Itoa(rand.Intn(100000000))
	cm, err := sendModel("POST", "/channel", c)
	if err != nil {
		return nil, err
	}
	return cm.(*models.Channel), nil
}

func UpdateChannel(cm *models.Channel) (*models.Channel, error) {
	url := fmt.Sprintf("/channel/%d", cm.Id)
	cmI, err := sendModel("POST", url, cm)
	if err != nil {
		return nil, err
	}

	return cmI.(*models.Channel), nil
}

func GetChannel(id int64) (*models.Channel, error) {

	url := fmt.Sprintf("/channel/%d", id)
	cm := models.NewChannel()
	cmI, err := sendModel("GET", url, cm)
	if err != nil {
		return nil, err
	}
	return cmI.(*models.Channel), nil
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
