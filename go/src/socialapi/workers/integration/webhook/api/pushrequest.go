package api

import (
	"socialapi/workers/integration/webhook"

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

	if _, err := uuid.ParseHex(r.Token); err != nil {
		return ErrTokenNotValid
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

func (r *PushRequest) verify() (*webhook.ChannelIntegration, error) {
	ti := webhook.NewChannelIntegration()
	err := ti.ByToken(r.Token)
	if err != nil {
		return nil, err
	}

	return ti, nil
}
