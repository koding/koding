package api

import (
	"socialapi/config"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

const (
	// EndpointInit defines app creation endpoint
	EndpointInit = "/countly/init"
)

// AddHandlers injects handlers for countly system
func AddHandlers(m *mux.Mux, cfg *config.Config) {
	return
	capi := NewCountlyAPI(cfg)
	m.AddHandler(
		handler.Request{
			Handler:  capi.Init,
			Name:     "countly-init",
			Type:     handler.GetRequest,
			Endpoint: EndpointInit,
		},
	)
}
