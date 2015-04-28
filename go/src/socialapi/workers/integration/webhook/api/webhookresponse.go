package api

type WebhookResponse struct {
	Success bool
	Error   string
	Data    map[string]interface{}
}

func NewWebhookResponse(success bool, err error) *WebhookResponse {
	wr := &WebhookResponse{
		Success: success,
	}

	if err != nil {
		wr.Error = err.Error()
	}

	return wr
}
