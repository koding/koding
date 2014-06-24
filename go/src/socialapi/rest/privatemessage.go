package rest

import (
	"encoding/json"
	"fmt"
	"socialapi/models"
)

func SendPrivateMessage(senderId int64, body string, groupName string, recipients []string) (*models.ChannelContainer, error) {

	pmr := models.PrivateMessageRequest{}
	pmr.AccountId = senderId
	pmr.Body = body
	pmr.GroupName = groupName
	pmr.Recipients = recipients

	url := "/privatemessage/send"
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

func GetPrivateMessages(accountId int64, groupName string) ([]models.ChannelContainer, error) {
	url := fmt.Sprintf("/privatemessage/list?accountId=%d&groupName=%s", accountId, groupName)
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
