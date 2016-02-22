package pinnedactivity

import (
	"socialapi/models"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func AddHandlers(m *mux.Mux) {

	// get pinning channel of the account
	m.AddHandler(
		handler.Request{
			Handler:  GetPinnedActivityChannel,
			Name:     "activity-pin-get-channel",
			Type:     handler.GetRequest,
			Endpoint: "/activity/pin/channel",
			Securer:  models.PinnedActivityReadSecurer,
		},
	)

	// pin a new status update
	m.AddHandler(
		handler.Request{
			Handler:  PinMessage,
			Name:     "activity-add-pinned-message",
			Type:     handler.PostRequest,
			Endpoint: "/activity/pin/add",
			Securer:  models.PinnedActivitySecurer,
		},
	)

	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  List,
			Name:     "activity-pin-list-message",
			Type:     handler.GetRequest,
			Endpoint: "/activity/pin/list",
			Securer:  models.PinnedActivityReadSecurer,
		},
	)

	// unpin a status update
	m.AddHandler(
		handler.Request{
			Handler:  UnpinMessage,
			Name:     "activity-remove-pinned-message",
			Type:     handler.PostRequest,
			Endpoint: "/activity/pin/remove",
			Securer:  models.PinnedActivitySecurer,
		},
	)

	// @todo add tests
	m.AddHandler(
		handler.Request{
			Handler:  Glance,
			Name:     "activity-pinned-message-glance",
			Type:     handler.PostRequest,
			Endpoint: "/activity/pin/glance",
			Securer:  models.PinnedActivitySecurer,
		},
	)
}
