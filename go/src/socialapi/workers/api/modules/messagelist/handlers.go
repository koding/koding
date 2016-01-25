package messagelist

import (
	"socialapi/models"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func AddHandlers(m *mux.Mux) {

	// list messages of the channel
	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  List,
			Name:     "channel-history-list",
			Endpoint: "/channel/{id}/history",
			Type:     handler.GetRequest,
			Securer:  models.MessageListReadSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  TempList,
			Name:     "channel-message-history-list",
			Endpoint: "/channel/{id}/list",
			Type:     handler.GetRequest,
			Securer:  models.MessageListReadSecurer,
		},
	)

	// message count of the channel
	m.AddHandler(
		handler.Request{
			Handler:  Count,
			Name:     "channel-history-count",
			Endpoint: "secure/channel/{id}/history/count",
			Type:     handler.GetRequest,
			Securer:  models.MessageListReadSecurer,
		},
	)
}
