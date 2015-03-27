package api

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"

	"github.com/koding/metrics"
)

func AddHandlers(m *mux.Mux, metric *metrics.Metrics) {
	m.AddHandler(
		handler.Request{
			Handler:  Parse,
			Name:     "mail-parse",
			Type:     handler.PostRequest,
			Endpoint: "/mail/parse",
			Metrics:  metric,
		},
	)
}
