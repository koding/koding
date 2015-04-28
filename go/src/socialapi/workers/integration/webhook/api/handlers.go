package api

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func (h *Handler) AddHandlers(m *mux.Mux) {
	m.AddSessionlessHandler(
		handler.Request{
			Handler:        h.Push,
			Name:           "webhook-push",
			Type:           handler.PostRequest,
			Endpoint:       "/webhook/push/{token}",
			CollectMetrics: true,
		},
	)

	// TODO list integrations handler

	m.AddHandler(
		handler.Request{
			Handler:        h.Prepare,
			Name:           "webhook-prepare",
			Type:           handler.PostRequest,
			Endpoint:       "/webhook/{name}/{token}",
			CollectMetrics: true,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:        h.FetchBotChannel,
			Name:           "bot-channel",
			Type:           handler.GetRequest,
			Endpoint:       "/botchannel",
			CollectMetrics: true,
		},
	)
}
