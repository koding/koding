package api

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
	"socialapi/workers/helper"
)

// AddHandlers adds handlers of collaboration
func AddHandlers(m *mux.Mux) {
	httpRateLimiter := helper.NewDefaultRateLimiter()

	m.AddHandler(
		handler.Request{
			Handler:   Ping,
			Name:      "collaboration-ping",
			Type:      handler.PostRequest,
			Endpoint:  "/collaboration/ping",
			Ratelimit: httpRateLimiter,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  End,
			Name:     "collaboration-end",
			Type:     handler.PostRequest,
			Endpoint: "/collaboration/end",
		},
	)
}
