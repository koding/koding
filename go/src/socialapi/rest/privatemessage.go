package rest

import (
	"encoding/json"
	"fmt"
	"socialapi/models"
	"socialapi/request"

	"github.com/google/go-querystring/query"
)

func SendPrivateMessage(senderId int64, body string, groupName string, recipients []string) (*models.ChannelContainer, error) {

	pmr := models.PrivateMessageRequest{}
	pmr.AccountId = senderId
	pmr.Body = body
	pmr.GroupName = groupName
	pmr.Recipients = recipients

	url := "/privatemessage/init"
	res, err := marshallAndSendRequest("POST", url, pmr)
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

func GetPrivateMessages(q *request.Query) ([]models.ChannelContainer, error) {
	v, err := query.Values(q)
	if err != nil {
		return nil, err
	}

	url := fmt.Sprintf("/privatemessage/list?%s", v.Encode())
	res, err := sendRequest("GET", url, nil)
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
