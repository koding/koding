package api

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"

	"github.com/koding/metrics"
)

func AddHandlers(m *mux.Mux, metric *metrics.Metrics) {
	// list notifications
	m.AddHandler(
		handler.Request{
			Handler:  List,
			Name:     "notification-list",
			Type:     handler.GetRequest,
			Endpoint: "/notification/{accountId}",
			Metrics:  metric,
		})

	// glance notifications
	m.AddHandler(
		handler.Request{
			Handler:        Glance,
			Name:           "notification-glance",
			Type:           handler.PostRequest,
			Endpoint:       "/notification/glance",
			Metrics:        metric,
			CollectMetrics: true,
		})

}
