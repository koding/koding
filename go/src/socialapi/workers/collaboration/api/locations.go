package api

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func AddHandlers(m *mux.Mux) {
	m.AddHandler(
		handler.Request{
			Handler:  Ping,
			Name:     "collaboration-ping",
			Type:     handler.PostRequest,
			Endpoint: "/collaboration/ping",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  Ping,
			Name:     "collaboration-end",
			Type:     handler.PostRequest,
			Endpoint: "/collaboration/end",
		},
	)
}
