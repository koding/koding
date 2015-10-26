package reply

import (
	"socialapi/models"
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
			Securer:  models.MessageSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  List,
			Name:     "reply-list",
			Type:     handler.GetRequest,
			Endpoint: "/message/{id}/reply",
			Securer:  models.MessageReadSecurer,
		},
	)
}
