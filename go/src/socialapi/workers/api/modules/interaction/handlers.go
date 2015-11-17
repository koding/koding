package interaction

import (
	"socialapi/models"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func AddHandlers(m *mux.Mux) {

	//----------------------------------------------------------
	// Message Interaction
	//----------------------------------------------------------
	m.AddHandler(
		handler.Request{
			Handler:  Add,
			Name:     "interactions-add",
			Type:     handler.PostRequest,
			Endpoint: "/message/{id}/interaction/{type}/add",
			Securer:  models.InteractionSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  Delete,
			Name:     "interactions-delete",
			Type:     handler.PostRequest,
			Endpoint: "/message/{id}/interaction/{type}/delete",
			Securer:  models.InteractionSecurer,
		},
	)

	// get all the interactions for message
	// exempt contents are filtered
	m.AddHandler(
		handler.Request{
			Handler:  List,
			Name:     "interactions-list-typed",
			Type:     handler.GetRequest,
			Endpoint: "/message/{id}/interaction/{type}",
			Securer:  models.InteractionReadSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  ListInteractedMessages,
			Name:     "interactions-list-liked",
			Type:     handler.GetRequest,
			Endpoint: "/account/{id}/interaction/{type}",
			Securer:  models.InteractionReadSecurer,
		},
	)
}
