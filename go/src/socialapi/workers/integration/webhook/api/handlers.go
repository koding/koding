package api

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
	"time"

	"github.com/PuerkitoBio/throttled"
	"github.com/PuerkitoBio/throttled/store"
)

func (h *Handler) AddHandlers(m *mux.Mux) {
	st := store.NewRedisStore(h.redis.Pool(), "throttle", 0)
	m.AddSessionlessHandler(
		handler.Request{
			Handler:  h.Push,
			Name:     "webhook-push",
			Type:     handler.PostRequest,
			Endpoint: "/push/{token}",
			Ratelimit: throttled.RateLimit(
				throttled.Q{Requests: 100, Window: time.Minute},
				&throttled.VaryBy{Path: true},
				st,
			),
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  h.List,
			Name:     "webhook-list",
			Type:     handler.GetRequest,
			Endpoint: "/",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  h.ListChannelIntegrations,
			Name:     "webhook-list-channel-integrations",
			Type:     handler.GetRequest,
			Endpoint: "/channelintegrations",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  h.RegenerateToken,
			Name:     "channel-integration-regenerate-token",
			Type:     handler.PostRequest,
			Endpoint: "/channelintegration/token",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  h.GetChannelIntegration,
			Name:     "channel-integration-get",
			Type:     handler.GetRequest,
			Endpoint: "/channelintegration/{id}",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  h.CreateChannelIntegration,
			Name:     "channel-integration-create",
			Type:     handler.PostRequest,
			Endpoint: "/channelintegration/create",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  h.UpdateChannelIntegration,
			Name:     "channel-integration-update",
			Type:     handler.PostRequest,
			Endpoint: "/channelintegration/{id}/update",
		},
	)

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
