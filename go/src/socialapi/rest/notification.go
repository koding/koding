package rest

import (
	"encoding/json"
	"fmt"
	"socialapi/models"
	notificationmodels "socialapi/workers/notification/models"

	"github.com/koding/api/utils"
)

func GetNotificationList(accountId int64, cacheEnabled bool) (*notificationmodels.NotificationResponse, error) {
	url := fmt.Sprintf("/notification/%d?cache=%t", accountId, cacheEnabled)

	res, err := utils.SendRequest("GET", url, nil)
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

	res, err := utils.SendModel("POST", "/notification/glance", n)
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

	channel, err := utils.SendModel("POST", "/channel", c)
	if err != nil {
		return nil, err
	}

	return AddChannelParticipant(channel.(*models.Channel).Id, followerId, followerId)
}

func SubscribeMessage(accountId, messageId int64) (interface{}, error) {
	n := notificationmodels.NewNotificationRequest()
	n.AccountId = accountId
	n.TargetId = messageId
	res, err := utils.SendModel("POST", "/notification/subscribe", n)
	if err != nil {
		return nil, err
	}

	return res, nil
}

func UnSubscribeMessage(accountId, messageId int64) (interface{}, error) {
	n := notificationmodels.NewNotificationRequest()
	n.AccountId = accountId
	n.TargetId = messageId
	res, err := utils.SendModel("POST", "/notification/unsubscribe", n)
	if err != nil {
		return nil, err
	}

	return res, nil
}
