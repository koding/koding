package api

import (
	"log"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"

	throttled "gopkg.in/throttled/throttled.v2"
	"gopkg.in/throttled/throttled.v2/store/redigostore"
)

func (h *Handler) AddHandlers(m *mux.Mux) {
	redisStore, err := redigostore.New(h.redis.Pool(), "throttle:", 0)
	if err != nil {
		// the implementation returns a nil, so it's impossible to get here
		log.Fatal(err.Error())
	}

	quota := throttled.RateQuota{
		MaxRate:  throttled.PerSec(1),
		MaxBurst: 1,
	}

	rateLimiter, err := throttled.NewGCRARateLimiter(redisStore, quota)
	if err != nil {
		// we exit because this is code error and must be handled. Exits only
		// if the values of quota doesn't make sense at all, so it's ok
		log.Fatalln(err)
	}

	httpRateLimiter := &throttled.HTTPRateLimiter{
		RateLimiter: rateLimiter,
		VaryBy:      &throttled.VaryBy{Path: true},
	}

	m.AddSessionlessHandler(
		handler.Request{
			Handler:   h.Push,
			Name:      "webhook-push",
			Type:      handler.PostRequest,
			Endpoint:  "/push/{token}",
			Ratelimit: httpRateLimiter,
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
			Handler:  h.Get,
			Name:     "webhook-get",
			Type:     handler.GetRequest,
			Endpoint: "/{name}",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  h.ListChannelIntegrations,
			Name:     "webhook-list-channel-integrations",
			Type:     handler.GetRequest,
			Endpoint: "/channelintegration",
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
			Endpoint: "/channelintegration",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  h.UpdateChannelIntegration,
			Name:     "channel-integration-update",
			Type:     handler.PostRequest,
			Endpoint: "/channelintegration/{id}",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  h.DeleteChannelIntegration,
			Name:     "channel-integration-delete",
			Type:     handler.DeleteRequest,
			Endpoint: "/channelintegration/{id}",
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
