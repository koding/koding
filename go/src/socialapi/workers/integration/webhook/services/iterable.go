package services

import "fmt"

type Iterable struct {
	Email      string
	EventName  string
	DataFields map[string]interface{}
	CampaignId string
}

func NewIterable(input *ServiceInput) (Iterable, error) {
	i := Iterable{}

	// for now just getting
	email := input.Key("email")
	i.Email, _ = email.(string)

	eventName := input.Key("eventName")
	i.EventName, _ = eventName.(string)

	dataFields := input.Key("dateFields")
	i.DataFields, _ = dataFields.(map[string]interface{})

	campaignId := input.Key("campaignId")
	i.CampaignId, _ = campaignId.(string)

	return i, nil
}

func (i Iterable) PrepareMessage(input *ServiceInput) string {
	value := input.Key("message")
	message, _ := value.(string)

	return message
}

func (i Iterable) Validate(input *ServiceInput) []error {
	return []error{}
}

func (i Iterable) PrepareEndpoint(token string) string {

	return fmt.Sprintf("/webhook/push/%s", token)
}

func (i Iterable) Output(input *ServiceInput) *ServiceOutput {
	val := input.Key("groupName")
	groupName, _ := val.(string)
	if groupName == "" {
		groupName = "koding"
	}

	return &ServiceOutput{
		Email:     i.Email,
		GroupName: groupName,
	}
}
