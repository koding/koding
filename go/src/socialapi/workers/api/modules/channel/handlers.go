package channel

import (
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
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  CheckParticipation,
			Name:     "channel-check-participation",
			Type:     handler.GetRequest,
			Endpoint: "/channel/checkparticipation",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  Delete,
			Name:     "channel-delete",
			Type:     handler.PostRequest,
			Endpoint: "/channel/{id}/delete",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  Update,
			Name:     "channel-update",
			Type:     handler.PostRequest,
			Endpoint: "/channel/{id}/update",
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
