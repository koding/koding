package api

import (
	"socialapi/workers/integration/webhook"
	"socialapi/workers/integration/webhook/services"
)

type PrepareRequest struct {
	Data      *services.ServiceInput `json:"data"`
	Token     string                 `json:"token"`
	Name      string                 `json:"name"`
	GroupName string                 `json:"groupName"`
	// Username is used for sending messages
	// to given user's bot channel
	Username string `json:"username"`
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
	return webhook.Cache.Integration.ByName(p.Name)
}
