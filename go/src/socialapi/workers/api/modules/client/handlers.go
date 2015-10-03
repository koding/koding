package client

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func AddHandlers(m *mux.Mux) {

	m.AddHandler(
		handler.Request{
			Handler:  Location,
			Name:     "client-location",
			Type:     handler.GetRequest,
			Endpoint: "/client/location",
		},
	)
}
