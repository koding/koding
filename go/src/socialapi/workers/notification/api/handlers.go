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
	// add account followed notification
	mux.Handle("POST", "/notification/follow", api.HandlerWrapper(Follow, "notification-follow"))
	// subscribe to message notification
	mux.Handle("POST", "/notification/subscribe", api.HandlerWrapper(SubscribeMessage, "notification-subscribe"))
	// unsubscribe from message notification
	mux.Handle("POST", "/notification/unsubscribe", api.HandlerWrapper(UnsubscribeMessage, "notification-unsubscribe"))

	return mux
}
