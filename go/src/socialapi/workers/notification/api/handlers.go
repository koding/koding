package api

import (
	"socialapi/workers/common/handler"

	"github.com/rcrowley/go-tigertonic"
)

// TODO wrap this TrieServeMux
func InitHandlers(mux *tigertonic.TrieServeMux) *tigertonic.TrieServeMux {
	// list notifications
	mux.Handle("GET", "/notification/{accountId}", handler.Wrapper(List, "notification-list", false))
	// glance notifications
	mux.Handle("POST", "/notification/glance", handler.Wrapper(Glance, "notification-glance", false))

	return mux
}
