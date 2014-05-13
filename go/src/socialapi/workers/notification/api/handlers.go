package api

import (
	"github.com/rcrowley/go-tigertonic"
	"net/http"
)

// todo think for a different method here
// also there must be an independent handler initializer
var (
	cors = tigertonic.NewCORSBuilder().AddAllowedOrigins("*")
)

func handlerWrapper(handler interface{}, logName string) http.Handler {
	return cors.Build(
		tigertonic.Timed(
			tigertonic.Marshaled(handler),
			logName,
			nil,
		))
}

func InitHandlers(mux *tigertonic.TrieServeMux) *tigertonic.TrieServeMux {
	// list notifications
	mux.Handle("GET", "/notification/{accountId}", handlerWrapper(List, "notification-list"))
	// glance notifications
	mux.Handle("POST", "/notification/glance", handlerWrapper(Glance, "notification-glance"))
	// add account followed notification
	mux.Handle("POST", "/notification/follow", handlerWrapper(Follow, "notification-follow"))
	// subscribe to message notification
	mux.Handle("POST", "/notification/subscribe", handlerWrapper(SubscribeMessage, "notification-subscribe"))
	// unsubscribe from message notification
	mux.Handle("POST", "/notification/unsubscribe", handlerWrapper(UnsubscribeMessage, "notification-unsubscribe"))

	return mux
}
