package realtimehelper

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"socialapi/config"
)

func PushMessage(channelId int64, eventName string, body interface{}) error {
	endpoint := fmt.Sprintf("%s/api/gatekeeper/channel/%d/push", config.MustGet().CustomDomain.Public, channelId)
	request := map[string]interface{}{
		"eventName": eventName,
		"body":      body,
	}

	return doRequest(endpoint, request)
}

func UpdateInstance(token string, eventName string, body interface{}) error {
	endpoint := fmt.Sprintf("%s/api/gatekeeper/message/%s/update", config.MustGet().CustomDomain.Public, token)
	request := map[string]interface{}{
		"eventName": eventName,
		"body":      body,
	}

	return doRequest(endpoint, request)
}

func NotifyUser(nickname, eventName string, body interface{}, groupName string) error {
	endpoint := fmt.Sprintf("%s/api/gatekeeper/account/%s/notify", config.MustGet().CustomDomain.Public, nickname)
	request := map[string]interface{}{
		"body": map[string]interface{}{
			"event":    eventName,
			"contents": body,
			"context":  groupName,
		},
	}

	return doRequest(endpoint, request)
}

func doRequest(endpoint string, request map[string]interface{}) error {
	payload, err := json.Marshal(request)
	if err != nil {
		return err
	}

	buf := bytes.NewBuffer(payload)
	client := &http.Client{}

	res, err := client.Post(endpoint, "application/json", buf)
	if err != nil {
		return err
	}

	if res.StatusCode != 200 {
		return fmt.Errorf(res.Status)
	}

	return nil
}
