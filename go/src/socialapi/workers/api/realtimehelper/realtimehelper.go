package realtimehelper

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"socialapi/config"
)

func PushMessage(channelId int64, eventName string, body interface{}) error {
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

	endpoint := fmt.Sprintf("%s/api/gatekeeper/channel/%d/push", config.MustGet().CustomDomain.Public, channelId)
	res, err := client.Post(endpoint, "application/json", buf)
	if err != nil {
		return err
	}

	if res.StatusCode != 200 {
		return fmt.Errorf(res.Status)
	}

	return nil
}
