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
