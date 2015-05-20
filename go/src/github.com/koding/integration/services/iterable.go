package services

import "fmt"

type Iterable struct {
	EventName  string
	DataFields map[string]interface{}
	CampaignId string
	Username   string
	Message    string
	GroupName  string
}

func NewIterable(input *ServiceInput) (Iterable, error) {
	i := Iterable{}

	eventName := input.Key("eventName")
	i.EventName, _ = eventName.(string)

	dataFields := input.Key("dateFields")
	i.DataFields, _ = dataFields.(map[string]interface{})

	campaignId := input.Key("campaignId")
	i.CampaignId, _ = campaignId.(string)

	message := input.Key("message")
	i.Message, _ = message.(string)

	groupName := input.Key("groupName")
	i.GroupName, _ = groupName.(string)

	username := input.Key("username")
	i.Username, _ = username.(string)

	return i, nil
}

func (i Iterable) PrepareMessage(input *ServiceInput) (string, error) {
	return i.Message, nil
}

func (i Iterable) PrepareEndpoint(token string) (string, error) {
	return fmt.Sprintf("/webhook/push/%s", token), nil
}

func (i Iterable) Output(input *ServiceInput) *ServiceOutput {
	return &ServiceOutput{
		GroupName: i.GroupName,
		Username:  i.Username,
	}
}
