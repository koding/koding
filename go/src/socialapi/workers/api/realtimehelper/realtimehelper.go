package realtimehelper

import (
	"socialapi/models"

	"github.com/koding/bongo"
)

func PushMessage(c *models.Channel, eventName string, body interface{}, secretNames []string) error {
	request := map[string]interface{}{
		"eventName": eventName,
		"body":      body,
		"token":     c.Token,
		"channel": map[string]interface{}{
			"id":           c.Id,
			"secretNames":  secretNames,
			"name":         c.Name,
			"typeConstant": c.TypeConstant,
			"groupName":    c.GroupName,
		},
	}

	return bongo.B.Emit("gatekeeper_channel_updated", request)
}

func UpdateInstance(token string, eventName string, body interface{}) error {
	request := map[string]interface{}{
		"token":     token,
		"eventName": eventName,
		"body":      body,
	}

	return bongo.B.Emit("gatekeeper_message_updated", request)
}

func NotifyUser(nickname, eventName string, body interface{}, groupName string) error {
	request := map[string]interface{}{
		"nickname": nickname,
		"body": map[string]interface{}{
			"event":    eventName,
			"contents": body,
			"context":  groupName,
		},
	}

	return bongo.B.Emit("gatekeeper_notify_user", request)
}
