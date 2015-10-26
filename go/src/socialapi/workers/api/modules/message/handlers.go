package message

import (
	"socialapi/models"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func AddHandlers(m *mux.Mux) {

	// add a new messages to the channel
	m.AddHandler(
		handler.Request{
			Handler:  Create,
			Name:     "channel-message-create",
			Type:     handler.PostRequest,
			Endpoint: "/channel/{id}/message",
			Securer:  models.MessageSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  Delete,
			Name:     models.REQUEST_NAME_MESSAGE_DELETE,
			Type:     handler.DeleteRequest,
			Endpoint: "/message/{id}",
			Securer:  models.MessageDeleteSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  Update,
			Name:     models.REQUEST_NAME_MESSAGE_UPDATE,
			Type:     handler.PostRequest,
			Endpoint: "/message/{id}",
			Securer:  models.MessageSecurer,
		},
	)

	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  Get,
			Name:     models.REQUEST_NAME_MESSAGE_GET,
			Type:     handler.GetRequest,
			Endpoint: "/message/{id}",
			Securer:  models.MessageReadSecurer,
		},
	)

	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  GetWithRelated,
			Name:     "message-get-with-related",
			Type:     handler.GetRequest,
			Endpoint: "/message/{id}/related",
			Securer:  models.MessageReadSecurer,
		},
	)

	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  GetBySlug,
			Name:     "message-get-by-slug",
			Type:     handler.GetRequest,
			Endpoint: "/message/slug/{slug}",
			Securer:  models.MessageReadSecurer,
		},
	)
}
