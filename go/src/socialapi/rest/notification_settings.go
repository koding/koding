package rest

import (
	"encoding/json"
	"fmt"
	"socialapi/models"
)

func GetNotificationSettings(channelId int64, token string) (*models.NotificationSettings, error) {
	url := fmt.Sprintf("/channel/%d/notificationsettings", channelId)
	n := models.NewNotificationSettings()
	ns, err := sendModelWithAuth("GET", url, n, token)
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

func DeleteNotificationSettings(id int64) error {
	url := fmt.Sprintf("/notificationsettings/%d", id)

	_, err := sendRequest("DELETE", url, nil)
	if err != nil {
		return err
	}
	return err
}
