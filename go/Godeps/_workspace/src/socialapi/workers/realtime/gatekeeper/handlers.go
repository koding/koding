package api

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func (h *Handler) AddHandlers(m *mux.Mux) {
	// channel subscription
	m.AddHandler(
		handler.Request{
			Handler:  h.SubscribeChannel,
			Name:     "channel-subscribe",
			Type:     handler.PostRequest,
			Endpoint: "/subscribe/channel",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  h.SubscribeNotification,
			Name:     "notification-subscribe",
			Type:     handler.PostRequest,
			Endpoint: "/subscribe/notification",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  h.GetToken,
			Name:     "get-token",
			Type:     handler.PostRequest,
			Endpoint: "/token",
		},
	)
}
