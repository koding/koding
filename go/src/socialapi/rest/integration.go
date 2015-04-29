package rest

import (
	"encoding/json"
	"errors"
	"fmt"
	"socialapi/workers/common/response"
	"socialapi/workers/integration/webhook/api"
	"socialapi/workers/integration/webhook/services"
	"strconv"
)

const IntegrationEndPoint = "http://localhost:7300"

var ErrTypecastError = errors.New("typecast error")

func DoPrepareRequest(data *services.ServiceInput, token string) error {
	url := fmt.Sprintf("%s/webhook/iterable/%s", IntegrationEndPoint, token)
	_, err := sendModel("POST", url, data)
	if err != nil {
		return err
	}

	return nil
}

func DoPushRequest(data *api.WebhookRequest, token string) error {

	url := fmt.Sprintf("%s/webhook/push/%s", IntegrationEndPoint, token)
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
	channelIdResponse, channelIdFound := res["channelId"]
	if !channelIdFound {
		return 0, fmt.Errorf("channelId field does not exit")
	}

	channelId, channelIdOk := channelIdResponse.(string)
	if !channelIdOk {
		return 0, ErrTypecastError
	}

	return strconv.ParseInt(channelId, 10, 64)
}
