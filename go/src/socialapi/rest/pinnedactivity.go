package rest

import (
	"fmt"
	"socialapi/models"
)

func FetchPinnedActivityChannel(accountId int64, groupName string) (*models.Channel, error) {
	url := fmt.Sprintf("/activity/pin/channel?accountId=%d&groupName=%s", accountId, groupName)
	cm := models.NewChannel()
	cmI, err := sendModel("GET", url, cm)
	if err != nil {
		return nil, err
	}
	return cmI.(*models.Channel), nil
}

func FetchPinnedMessages(accountId int64, groupName string) (*models.HistoryResponse, error) {
	url := fmt.Sprintf("/activity/pin/list?accountId=%d&groupName=%s", accountId, groupName)
	history, err := sendModel("GET", url, models.NewHistoryResponse())
	if err != nil {
		return nil, err
	}
	return history.(*models.HistoryResponse), nil
}

func AddPinnedMessage(accountId, messageId int64, groupName string) (*models.PinRequest, error) {
	req := models.NewPinRequest()
	req.AccountId = accountId
	req.MessageId = messageId
	req.GroupName = groupName

	url := "/activity/pin/add"
	cmI, err := sendModel("POST", url, req)
	if err != nil {
		return nil, err
	}
	return cmI.(*models.PinRequest), nil

}

func RemovePinnedMessage(accountId, messageId int64, groupName string) (*models.PinRequest, error) {
	req := models.NewPinRequest()
	req.AccountId = accountId
	req.MessageId = messageId
	req.GroupName = groupName

	url := "/activity/pin/remove"
	cmI, err := sendModel("POST", url, req)
	if err != nil {
		return nil, err
	}
	return cmI.(*models.PinRequest), nil

}
