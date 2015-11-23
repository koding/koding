package api

import (
	"socialapi/workers/integration/webhook"
	"strings"

	uuid "github.com/satori/go.uuid"
)

// PushRequest is used as input data for /push endpoint
type PushRequest struct {
	webhook.Message
	Token string `json:"token"`
}

// tests are handled within webhook_test file
func (r *PushRequest) validate() error {
	if r.Token == "" {
		return ErrTokenNotSet
	}

	token := strings.ToLower(r.Token)
	if _, err := uuid.ParseHex(token); err != nil {
		return ErrTokenNotValid
	}

	if r.Body == "" {
		return ErrBodyNotSet
	}

	return nil
}

func (r *PushRequest) fetchChannelIntegration() (*webhook.ChannelIntegration, error) {
	return webhook.Cache.ChannelIntegration.ByToken(r.Token)
}
