package api

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"

	"github.com/koding/metrics"
)

func AddHandlers(m *mux.Mux, metric *metrics.Metrics) {
	m.AddHandler(
		handler.Request{
			Handler:  List,
			Name:     "permission-list",
			Type:     handler.GetRequest,
			Endpoint: "/permission",
			Metrics:  metric,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  List,
			Name:     "permission-list-channel",
			Type:     handler.GetRequest,
			Endpoint: "/permission/channel/{id}",
			Metrics:  metric,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  Create,
			Name:     "permission-create",
			Type:     handler.PostRequest,
			Endpoint: "/permission",
			Metrics:  metric,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  Update,
			Name:     "permission-update",
			Type:     handler.PostRequest,
			Endpoint: "/permission/{id}",
			Metrics:  metric,
		},
	)
}
