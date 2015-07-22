package rest

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"socialapi/workers/common/response"
	"socialapi/workers/integration/webhook/api"
	"strconv"
)

const (
	IntegrationEndPoint = "http://localhost:7300"
	MiddlewareEndPoint  = "http://localhost:7350"
)

var ErrTypecastError = errors.New("typecast error")

func DoGithubPush(data string, token string) error {
	url := fmt.Sprintf("%s/push/github/%s", MiddlewareEndPoint, token)

	reader := bytes.NewReader([]byte(data))
	req, err := http.NewRequest("POST", url, reader)
	if err != nil {
		return nil
	}

	req.Header.Set("content-type", "application/json")
	req.Header.Set("User-Agent", "GitHub-Hookshot/aef1442")
	req.Header.Set("X-GitHub-Delivery", "9c072a80-19f7-11e5-8043-a9077ed0d1e6")
	req.Header.Set("X-GitHub-Event", "push")

	req.Header.Set("X-Hub-Signature", "sha1=151b614b891bec1d49f86bee527d841c8eec9abd")

	client := http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}

	if resp.StatusCode != 200 {
		return errors.New(resp.Status)
	}

	return nil
}

func DoPushRequest(data *api.PushRequest, token string) error {
	url := fmt.Sprintf("%s/push/%s", IntegrationEndPoint, token)
	_, err := sendModel("POST", url, data)

	return err
}

func DoBotChannelRequest(token string) (int64, error) {
	req := new(response.SuccessResponse)
	url := fmt.Sprintf("%s/botchannel", IntegrationEndPoint)

	resp, err := marshallAndSendRequestWithAuth("GET", url, req, token)
	if err != nil {
		return 0, err
	}

	err = json.Unmarshal(resp, req)
	if err != nil {
		return 0, err
	}
	res, ok := req.Data.(map[string]interface{})
	if !ok {
		return 0, ErrTypecastError
	}
	channelResponse, channelFound := res["channel"]
	if !channelFound {
		return 0, fmt.Errorf("channel field does not exit")
	}

	cr, channelResponseOk := channelResponse.(map[string]interface{})
	if !channelResponseOk {
		return 0, ErrTypecastError
	}

	channelIdResponse, channelIdFound := cr["id"]
	if !channelIdFound {
		return 0, fmt.Errorf("channel.id field does not exist")
	}

	channelId, channelIdOk := channelIdResponse.(string)
	if !channelIdOk {
		return 0, ErrTypecastError
	}

	return strconv.ParseInt(channelId, 10, 64)
}
