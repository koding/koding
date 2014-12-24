package api

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func (h *Handler) AddHandlers(m *mux.Mux) {

	// channel subscription
	m.AddSessionlessHandler(
		handler.Request{
			Handler:        h.SubscribeChannel,
			Name:           "channel-subscribe",
			Type:           handler.PostRequest,
			Endpoint:       "/subscribe/channel",
			CollectMetrics: true,
		})

	m.AddSessionlessHandler(
		handler.Request{
			Handler:        h.SubscribeNotification,
			Name:           "notification-subscribe",
			Type:           handler.PostRequest,
			Endpoint:       "/subscribe/notification",
			CollectMetrics: true,
		})

	m.AddSessionlessHandler(
		handler.Request{
			Handler:        h.SubscribeMessage,
			Name:           "message-subscribe",
			Type:           handler.PostRequest,
			Endpoint:       "/subscribe/message",
			CollectMetrics: true,
		})
}
