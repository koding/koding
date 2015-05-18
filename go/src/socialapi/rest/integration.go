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

const (
	IntegrationEndPoint = "http://localhost:7300"
	MiddlewareEndPoint  = "http://localhost:7350"
)

var ErrTypecastError = errors.New("typecast error")

func DoPrepareRequest(data *services.ServiceInput, token string) error {
	url := fmt.Sprintf("%s/push/iterable/%s", MiddlewareEndPoint, token)
	_, err := sendModel("POST", url, data)
	if err != nil {
		return err
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
