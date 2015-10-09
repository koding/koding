package popular

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func AddHandlers(m *mux.Mux) {

	// get popular topics
	// exempt contents are filtered
	// TODO add caching
	m.AddHandler(
		handler.Request{
			Handler:  ListTopics,
			Name:     "list-popular-topics",
			Type:     handler.GetRequest,
			Endpoint: "/popular/topics/{statisticName}",
			// Securer: #no need for securer
		},
	)

	// exempt contents are filtered
	// TODO add caching
	m.AddHandler(
		handler.Request{
			Handler:  ListPosts,
			Name:     "list-popular-posts",
			Type:     handler.GetRequest,
			Endpoint: "/popular/posts/{channelName}",
			// Securer: #no need for securer
		},
	)
}
