package api

import (
	"net/http"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
	"time"

	"github.com/juju/ratelimit"
	"github.com/koding/cache"
)

func AddHandlers(m *mux.Mux) {
	m.AddHandler(
		handler.Request{
			Handler:  Ping,
			Name:     "collaboration-ping",
			Type:     handler.PostRequest,
			Endpoint: "/collaboration/ping",
			Ratelimit: func() func(r *http.Request) *ratelimit.Bucket {
				var tokenCache = cache.NewLRU(1000)
				return func(r *http.Request) *ratelimit.Bucket {
					key := ""
					cookie, err := r.Cookie("clientId")
					if err == nil {
						key = cookie.String()
					}

					i, _ := tokenCache.Get(key)
					if i != nil {
						if t, ok := i.(*ratelimit.Bucket); ok {
							return t
						}
					}

					t := ratelimit.NewBucket(
						time.Second*10, // add one token item per 10sec interval
						10,             // max token count
					)
					tokenCache.Set(key, t)
					return t
				}
			}(),
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
