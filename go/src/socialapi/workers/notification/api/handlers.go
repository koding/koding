package api

import (
	"socialapi/workers/common/handler"

	"github.com/rcrowley/go-tigertonic"
)

// TODO wrap this TrieServeMux
func InitHandlers(mux *tigertonic.TrieServeMux) *tigertonic.TrieServeMux {
	// list notifications
	mux.Handle("GET", "/notification/{accountId}", handler.Wrapper(
		handler.Request{
			Handler: List,
			Name:    "notification-list",
		},
	))

	// glance notifications
	mux.Handle("POST", "/notification/glance", handler.Wrapper(
		handler.Request{
			Handler:        Glance,
			Name:           "notification-glance",
			CollectMetrics: true,
		},
	))

	return mux
}
