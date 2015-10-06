package channel

import (
	"socialapi/models"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func AddHandlers(m *mux.Mux) {
	m.AddHandler(
		handler.Request{
			Handler:  Create,
			Name:     "channel-create",
			Type:     handler.PostRequest,
			Endpoint: "/channel",
			Securer:  models.ChannelSecurer,
		},
	)

	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  List,
			Name:     "channel-list",
			Type:     handler.GetRequest,
			Endpoint: "/channel",
			Securer:  models.ChannelReadSecurer,
		},
	)

	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  Search,
			Name:     "channel-search",
			Type:     handler.GetRequest,
			Endpoint: "/channel/search",
			Securer:  models.ChannelReadSecurer,
		},
	)

	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  ByName,
			Name:     "channel-get-byname",
			Type:     handler.GetRequest,
			Endpoint: "/channel/name/{name}",
			Securer:  models.ChannelReadSecurer,
		},
	)

	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  Get,
			Name:     "channel-get",
			Type:     handler.GetRequest,
			Endpoint: "/channel/{id}",
			Securer:  models.ChannelReadSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  CheckParticipation,
			Name:     "channel-check-participation",
			Type:     handler.GetRequest,
			Endpoint: "/channel/checkparticipation",
			Securer:  models.ChannelReadSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  Delete,
			Name:     "channel-delete",
			Type:     handler.PostRequest,
			Endpoint: "/channel/{id}/delete",
			Securer:  models.ChannelSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  Update,
			Name:     "channel-update",
			Type:     handler.PostRequest,
			Endpoint: "/channel/{id}/update",
			Securer:  models.ChannelSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  ByParticipants,
			Name:     "channel-by-participants",
			Type:     handler.GetRequest,
			Endpoint: "/channel/by/participants",
		},
	)
}
