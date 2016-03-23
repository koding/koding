package api

import (
	"socialapi/config"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

const (
	OauthAuthorization = "oauth-authorization"
	GenerateToken      = "generate-token"
)

// AddHandlers adds handlers for slack integration
func AddHandlers(m *mux.Mux, config *config.Config) {
	oauth := &Oauth{}
	m.AddUnscopedHandler(
		handler.Request{
			Handler:  oauth.AuthorizeClient,
			Name:     OauthAuthorization,
			Type:     handler.GetRequest,
			Endpoint: "/oauth/authorize",
		},
	)
	m.AddUnscopedHandler(
		handler.Request{
			Handler:  oauth.GenerateToken,
			Name:     GenerateToken,
			Type:     handler.GetRequest,
			Endpoint: "/oauth/token",
		},
	)

}
