package api

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func (h *Handler) AddHandlers(m *mux.Mux) {
	m.AddHandler(
		handler.Request{
			Handler:  h.Push,
			Name:     "webhook-push",
			Type:     handler.PostRequest,
			Endpoint: "/webhook/push/{token}",
		},
	)
}
