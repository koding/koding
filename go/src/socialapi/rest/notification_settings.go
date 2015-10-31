package rest

import (
	"encoding/json"
	"fmt"
	"socialapi/models"
)

func GetNotificationSetting(channelId int64, token string) (*models.NotificationSetting, error) {
	url := fmt.Sprintf("/channel/%d/notificationsetting", channelId)
	n := models.NewNotificationSetting()
	ns, err := sendModelWithAuth("GET", url, n, token)
	if err != nil {
		return nil, err
	}
	return ns.(*models.NotificationSetting), nil
}

func CreateNotificationSetting(ns *models.NotificationSetting, token string) (*models.NotificationSetting, error) {

	url := fmt.Sprintf("/channel/%d/notificationsetting", ns.ChannelId)
	res, err := marshallAndSendRequestWithAuth("POST", url, ns, token)
	if err != nil {
		return nil, err
	}

	var notification models.NotificationSetting
	err = json.Unmarshal(res, &notification)
	if err != nil {
		return nil, err
	}

	return &notification, nil
}

func UpdateNotificationSetting(ns *models.NotificationSetting, token string) (*models.NotificationSetting, error) {

	url := fmt.Sprintf("/notificationsetting/%d", ns.Id)
	res, err := marshallAndSendRequestWithAuth("POST", url, ns, token)
	if err != nil {
		return nil, err
	}

	var notification models.NotificationSetting
	err = json.Unmarshal(res, &notification)
	if err != nil {
		return nil, err
	}

	return &notification, nil
}

func DeleteNotificationSetting(id int64) error {
	url := fmt.Sprintf("/notificationsetting/%d", id)

	_, err := sendRequest("DELETE", url, nil)
	if err != nil {
		return err
	}
	return err
}
