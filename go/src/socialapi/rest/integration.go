package rest

import (
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

func MakeBotChannelRequest(data *api.BotChannelRequest) (int64, error) {
	url := fmt.Sprintf("%s/account/%s/bot-channel", IntegrationEndPoint, data.Username)
	resp, err := sendModel("POST", url, data)
	if err != nil {
		return 0, err
	}

	response := resp.(map[string]string)
	channelId, _ := response["channelId"]

	return strconv.ParseInt(channelId, 10, 64)
}
