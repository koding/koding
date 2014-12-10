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

	return doRequest(endpoint, eventName, body)
}

func UpdateInstance(token string, eventName string, body interface{}) error {
	endpoint := fmt.Sprintf("%s/api/gatekeeper/message/%s/update", config.MustGet().CustomDomain.Public, token)

	return doRequest(endpoint, eventName, body)
}

func doRequest(endpoint, eventName string, body interface{}) error {
	request := map[string]interface{}{
		"eventName": eventName,
		"body":      body,
	}

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
