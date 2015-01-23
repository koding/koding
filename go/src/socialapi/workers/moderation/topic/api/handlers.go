package api

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func AddHandlers(m *mux.Mux) {
	m.AddHandler(
		handler.Request{
			Handler:  CreateLink,
			Name:     models.ModerationChannelCreateLink,
			Type:     handler.PostRequest,
			Endpoint: "/moderation/channel/{rootId}/link",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  GetLink,
			Name:     models.ModerationChannelGetLink,
			Type:     handler.GetRequest,
			Endpoint: "/moderation/channel/{rootId}/link",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  Unlink,
			Name:     models.ModerationChannelDeleteLink,
			Type:     handler.DeleteRequest,
			Endpoint: "/moderation/channel/{rootId}/link/{leafId}",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  Blacklist,
			Name:     models.ModerationChannelBlacklist,
			Type:     handler.DeleteRequest,
			Endpoint: "/moderation/channel/{rootId}",
		},
	)
}
