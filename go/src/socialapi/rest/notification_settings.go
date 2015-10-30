package rest

import (
	"encoding/json"
	"fmt"
	"socialapi/models"
)

func GetNotificationSettings(channelId int64, accountId int64) (*models.NotificationSettings, error) {
	url := fmt.Sprintf("/channel/%d/notificationsettings?accountId=%d", channelId, accountId)
	n := models.NewNotificationSettings()
	ns, err := sendModel("GET", url, n)
	if err != nil {
		return nil, err
	}
	return ns.(*models.NotificationSettings), nil
}

func CreateNotificationSettings(ns *models.NotificationSettings, token string) (*models.NotificationSettings, error) {

	url := fmt.Sprintf("/channel/%d/notificationsettings", ns.ChannelId)
	res, err := marshallAndSendRequestWithAuth("POST", url, ns, token)
	if err != nil {
		return nil, err
	}

	var notification models.NotificationSettings
	err = json.Unmarshal(res, &notification)
	if err != nil {
		return nil, err
	}

	return &notification, nil
}

func UpdateNotificationSettings(ns *models.NotificationSettings, token string) (*models.NotificationSettings, error) {

	url := fmt.Sprintf("/notificationsettings/%d", ns.Id)
	res, err := marshallAndSendRequestWithAuth("POST", url, ns, token)
	if err != nil {
		return nil, err
	}

	var notification models.NotificationSettings
	err = json.Unmarshal(res, &notification)
	if err != nil {
		return nil, err
	}

	return &notification, nil
}
