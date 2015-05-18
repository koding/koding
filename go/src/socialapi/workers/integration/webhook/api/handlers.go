package api

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func (h *Handler) AddHandlers(m *mux.Mux) {
	m.AddSessionlessHandler(
		handler.Request{
			Handler:  h.Push,
			Name:     "webhook-push",
			Type:     handler.PostRequest,
			Endpoint: "/push/{token}",
		},
	)

	// TODO list integrations handler

	m.AddHandler(
		handler.Request{
			Handler:  h.FetchBotChannel,
			Name:     "webhook-bot-channel",
			Type:     handler.GetRequest,
			Endpoint: "/botchannel",
		},
	)

	m.AddSessionlessHandler(
		handler.Request{
			Handler:  h.FetchGroupBotChannel,
			Name:     "webhook-group-bot-channel",
			Type:     handler.GetRequest,
			Endpoint: "/botchannel/{token}/user/{username}",
		},
	)

}
