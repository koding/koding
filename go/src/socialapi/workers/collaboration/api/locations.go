package api

import (
	"log"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"

	"gopkg.in/throttled/throttled.v2"
	"gopkg.in/throttled/throttled.v2/store/memstore"
)

func AddHandlers(m *mux.Mux) {
	memStore, err := memstore.New(65536)
	if err != nil {
		// errors only for non positve numbers, so no worries :)
		log.Fatal(err)
	}

	quota := throttled.RateQuota{
		MaxRate:  throttled.PerSec(11),
		MaxBurst: 12,
	}

	rateLimiter, err := throttled.NewGCRARateLimiter(memStore, quota)
	if err != nil {
		// we exit because this is code error and must be handled
		log.Fatalln(err)
	}

	httpRateLimiter := &throttled.HTTPRateLimiter{
		RateLimiter: rateLimiter,
		VaryBy:      &throttled.VaryBy{Cookies: []string{"clientId"}},
	}

	m.AddHandler(
		handler.Request{
			Handler:   Ping,
			Name:      "collaboration-ping",
			Type:      handler.PostRequest,
			Endpoint:  "/collaboration/ping",
			Ratelimit: httpRateLimiter,
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
