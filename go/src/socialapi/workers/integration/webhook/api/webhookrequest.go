package api

import "socialapi/workers/integration/webhook"

// WebhookRequest is used as input data for /push endpoint
type WebhookRequest struct {
	*webhook.Message
	GroupName string
	Token     string
}

// tests are handled within webhook_test file
func (r *WebhookRequest) validate() error {
	if r.Token == "" {
		return ErrTokenNotSet
	}

	if r.Body == "" {
		return ErrBodyNotSet
	}

	if r.ChannelId == 0 {
		return ErrChannelNotSet
	}

	if r.GroupName == "" {
		return ErrGroupNotSet
	}

	return nil
}

func (r *WebhookRequest) verify() (*webhook.ChannelIntegration, error) {
	ti := webhook.NewChannelIntegration()
	err := ti.ByToken(r.Token)
	if err != nil {
		return nil, err
	}

	return ti, nil
}
