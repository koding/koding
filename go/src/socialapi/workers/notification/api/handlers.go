package api

import (
	"github.com/koding/api"
	"github.com/rcrowley/go-tigertonic"
)

// TODO wrap this TrieServeMux
func InitHandlers(mux *tigertonic.TrieServeMux) *tigertonic.TrieServeMux {
	// list notifications
	mux.Handle("GET", "/notification/{accountId}", api.HandlerWrapper(List, "notification-list"))
	// glance notifications
	mux.Handle("POST", "/notification/glance", api.HandlerWrapper(Glance, "notification-glance"))

	return mux
}
