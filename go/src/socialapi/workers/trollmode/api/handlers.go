package api

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func AddHandlers(m *mux.Mux) {
	m.AddHandler(
		handler.Request{
			Handler:  Mark,
			Name:     "trollmode-mark",
			Type:     handler.PostRequest,
			Endpoint: "/trollmode/{accountId}",
		})

	m.AddHandler(
		handler.Request{
			Handler:  UnMark,
			Name:     "trollmode-unmark",
			Type:     handler.DeleteRequest,
			Endpoint: "/trollmode/{accountId}",
		})
}
