package handlers

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func (h *Handler) AddHandlers(m *mux.Mux) {

	// channel authentication
	m.AddSessionlessHandler(
		handler.Request{
			Handler:        h.Authenticate,
			Name:           "channel-authenticate",
			Type:           handler.PostRequest,
			Endpoint:       "/channel/{name}/authenticate",
			CollectMetrics: true,
		})

	// channel push message
	m.AddSessionlessHandler(
		handler.Request{
			Handler:        h.Push,
			Name:           "channel-push",
			Type:           handler.PostRequest,
			Endpoint:       "/channel/{name}/push",
			CollectMetrics: true,
		})
}
