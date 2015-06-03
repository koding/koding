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
				throttled.Q{Requests: 101, Window: time.Minute},
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
			Endpoint: "/list",
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
