package realtimehelper

import "github.com/koding/bongo"

func PushMessage(channelId int64, eventName string, body interface{}) error {
	request := map[string]interface{}{
		"channelId": channelId,
		"eventName": eventName,
		"body":      body,
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
