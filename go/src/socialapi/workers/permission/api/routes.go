package api

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func AddHandlers(m *mux.Mux) {
	m.AddHandler(
		handler.Request{
			Handler:  List,
			Name:     "permission-list",
			Type:     handler.GetRequest,
			Endpoint: "/permission",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  List,
			Name:     "permission-list-channel",
			Type:     handler.GetRequest,
			Endpoint: "/permission/channel/{id}",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  Create,
			Name:     "permission-create",
			Type:     handler.PostRequest,
			Endpoint: "/permission",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  Update,
			Name:     "permission-update",
			Type:     handler.PostRequest,
			Endpoint: "/permission/{id}",
		},
	)
}
