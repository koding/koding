package api

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func AddHandlers(m *mux.Mux) {
	// list notifications
	m.AddHandler(
		handler.Request{
			Handler:  List,
			Name:     "notification-list",
			Type:     handler.GetRequest,
			Endpoint: "/notification/{accountId}",
		})

	// glance notifications
	m.AddHandler(
		handler.Request{
			Handler:        Glance,
			Name:           "notification-glance",
			Type:           handler.PostRequest,
			Endpoint:       "/notification/glance",
			CollectMetrics: true,
		})

}
