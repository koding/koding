package api

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func AddHandlers(m *mux.Mux) {
	m.AddHandler(
		handler.Request{
			Handler:  Parse,
			Name:     "mail-parse",
			Type:     handler.PostRequest,
			Endpoint: "/mail/parse",
		},
	)
}
