package reply

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func AddHandlers(m *mux.Mux) {

	m.AddHandler(
		handler.Request{
			Handler:  Create,
			Name:     "reply-create",
			Type:     handler.PostRequest,
			Endpoint: "/message/{id}/reply",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  List,
			Name:     "reply-list",
			Type:     handler.GetRequest,
			Endpoint: "/message/{id}/reply",
		},
	)
}
