package rest

import (
	"encoding/json"
	"fmt"
	"socialapi/workers/integration/webhook/api"
	"socialapi/workers/integration/webhook/services"
	"strconv"
)

const IntegrationEndPoint = "http://localhost:7300"

func MakePrepareRequest(data *services.ServiceInput, token string) error {
	url := fmt.Sprintf("%s/webhook/iterable/%s", IntegrationEndPoint, token)
	_, err := sendModel("POST", url, data)
	if err != nil {
		return err
	}

	return nil
}

func MakePushRequest(data *api.WebhookRequest, token string) error {

	url := fmt.Sprintf("%s/webhook/push/%s", IntegrationEndPoint, token)
	_, err := sendModel("POST", url, data)
	if err != nil {
		return err
	}

	return nil
}

func MakeBotChannelRequest(token string) (int64, error) {
	data := new(api.WebhookResponse)
	url := fmt.Sprintf("%s/botchannel", IntegrationEndPoint)

	resp, err := marshallAndSendRequestWithAuth("GET", url, data, token)
	if err != nil {
		return 0, err
	}

	err = json.Unmarshal(resp, data)
	if err != nil {
		return 0, err
	}
	channelIdResponse, _ := data.Data["channelId"]
	channelId, _ := channelIdResponse.(string)

	return strconv.ParseInt(channelId, 10, 64)
}
