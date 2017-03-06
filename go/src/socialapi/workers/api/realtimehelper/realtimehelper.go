package realtimehelper

import (
	"socialapi/models"
	"strconv"

	"github.com/koding/bongo"
)

const NotificationTypeMessage = "message"

func PushMessage(c *models.Channel, eventName string, body interface{}) error {

	request := map[string]interface{}{
		"eventName": eventName,
		"body":      body,
		"channel": map[string]interface{}{
			"id":           strconv.FormatInt(c.Id, 10),
			"name":         c.Name,
			"typeConstant": c.TypeConstant,
			"groupName":    c.GroupName,
			"token":        c.Token,
		},
	}

	return bongo.B.Emit("dispatcher_channel_updated", request)
}

func NotifyUser(a *models.Account, eventName string, body interface{}, groupName string) error {
	request := map[string]interface{}{
		"account":   a,
		"eventName": NotificationTypeMessage,
		"body": map[string]interface{}{
			"event":    eventName,
			"contents": body,
			"context":  groupName,
		},
	}

	return bongo.B.Emit("dispatcher_notify_user", request)
}

func NotifyGroup(groupName string, eventName string, body interface{}) error {
	request := map[string]interface{}{
		"groupName": groupName,
		"eventName": NotificationTypeMessage,
		"body": map[string]interface{}{
			"event":    eventName,
			"context":  groupName,
			"contents": body,
		},
	}

	return bongo.B.Emit("dispatcher_notify_group", request)
}
