package rest

import (
	"encoding/json"
	"fmt"
	"socialapi/models"
	notificationmodels "socialapi/workers/notification/models"
)

func GetNotificationList(accountId int64) (*notificationmodels.NotificationResponse, error) {
	url := fmt.Sprintf("/notification/%d", accountId)

	res, err := sendRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	var notificationList notificationmodels.NotificationResponse
	err = json.Unmarshal(res, &notificationList)
	if err != nil {
		return nil, err
	}

	return &notificationList, nil
}

func GlanceNotifications(accountId int64) (interface{}, error) {
	n := notificationmodels.NewNotification()
	n.AccountId = accountId

	res, err := sendModel("POST", "/notification/glance", n)
	if err != nil {
		return nil, err
	}

	return res, nil
}

func FollowNotification(followerId, followeeId int64) (interface{}, error) {
	c := models.NewChannel()
	c.GroupName = fmt.Sprintf("FollowerTest-%d", followeeId)
	c.TypeConstant = models.Channel_TYPE_FOLLOWERS
	c.CreatorId = followeeId

	channel, err := sendModel("POST", "/channel", c)
	if err != nil {
		return nil, err
	}

	return AddChannelParticipant(channel.(*models.Channel).Id, followerId, followerId)
}

func SubscribeMessage(accountId, messageId int64, groupName string) (interface{}, error) {
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

func UnsubscribeMessage(accountId, messageId int64, groupName string) (*models.PinRequest, error) {
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
