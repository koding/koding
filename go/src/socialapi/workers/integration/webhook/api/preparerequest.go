package api

import (
	"socialapi/workers/integration/webhook"
	"socialapi/workers/integration/webhook/services"
)

type PrepareRequest struct {
	Data      *services.ServiceInput
	Token     string
	Name      string
	GroupName string
	// Username is used for sending messages
	// to given user's bot channel
	Username string
}

func (p *PrepareRequest) validate() error {
	if p.Token == "" {
		return ErrTokenNotSet
	}

	if p.Name == "" {
		return ErrNameNotSet
	}

	return nil
}

func (p *PrepareRequest) verify() (*webhook.Integration, error) {
	i := webhook.NewIntegration()
	err := i.ByName(p.Name)
	if err != nil {
		return nil, err
	}

	return i, nil
}
