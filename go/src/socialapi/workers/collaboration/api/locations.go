package api

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
	"time"

	"github.com/PuerkitoBio/throttled"
	"github.com/PuerkitoBio/throttled/store"
)

func AddHandlers(m *mux.Mux) {
	m.AddHandler(
		handler.Request{
			Handler:  Ping,
			Name:     "collaboration-ping",
			Type:     handler.PostRequest,
			Endpoint: "/collaboration/ping",
			Ratelimit: throttled.RateLimit(
				throttled.Q{Requests: 11, Window: time.Second},
				&throttled.VaryBy{Cookies: []string{"clientId"}},
				store.NewMemStore(1000),
			),
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  End,
			Name:     "collaboration-end",
			Type:     handler.PostRequest,
			Endpoint: "/collaboration/end",
		},
	)
}
