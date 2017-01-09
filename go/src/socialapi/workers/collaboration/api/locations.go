package api

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
	"socialapi/workers/helper"

	"github.com/koding/cache"
)

// AddHandlers adds handlers of collaboration
func AddHandlers(m *mux.Mux, mgoCache *cache.MongoCache) {
	httpRateLimiter := helper.NewDefaultRateLimiter()

	cs := &CacheStore{
		MongoCache: mgoCache,
	}

	m.AddHandler(
		handler.Request{
			Handler:   cs.Ping,
			Name:      "collaboration-ping",
			Type:      handler.PostRequest,
			Endpoint:  "/collaboration/ping",
			Ratelimit: httpRateLimiter,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  cs.End,
			Name:     "collaboration-end",
			Type:     handler.PostRequest,
			Endpoint: "/collaboration/end",
		},
	)
}
