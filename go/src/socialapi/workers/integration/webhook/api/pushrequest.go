package api

import (
	"socialapi/workers/integration/webhook"
	"strings"

	"github.com/nu7hatch/gouuid"
)

// PushRequest is used as input data for /push endpoint
type PushRequest struct {
	webhook.Message
	GroupName string `json:"groupName"`
	Token     string `json:"token"`
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

	if r.ChannelId == 0 {
		return ErrChannelNotSet
	}

	return nil
}

func (r *PushRequest) verify() (*webhook.ChannelIntegration, error) {
	return webhook.Cache.ChannelIntegration.ByToken(r.Token)
}
