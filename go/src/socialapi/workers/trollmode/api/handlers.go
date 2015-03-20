package api

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"

	"github.com/koding/metrics"
)

func AddHandlers(m *mux.Mux, metric *metrics.Metrics) {
	m.AddHandler(
		handler.Request{
			Handler:  Mark,
			Name:     "trollmode-mark",
			Type:     handler.PostRequest,
			Endpoint: "/trollmode/{accountId}",
			Metrics:  metric,
		})

	m.AddHandler(
		handler.Request{
			Handler:  UnMark,
			Name:     "trollmode-unmark",
			Type:     handler.DeleteRequest,
			Endpoint: "/trollmode/{accountId}",
			Metrics:  metric,
		})
}
