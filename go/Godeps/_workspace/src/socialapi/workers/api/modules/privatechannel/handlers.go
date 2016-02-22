package privatechannel

import (
	"socialapi/models"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func AddHandlers(m *mux.Mux) {

	m.AddHandler(
		handler.Request{
			Handler:  Init,
			Name:     "privatechannel-init",
			Type:     handler.PostRequest,
			Endpoint: "/privatechannel/init",
			Securer:  models.PrivateMessageSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  Send,
			Name:     "privatechannel-send",
			Type:     handler.PostRequest,
			Endpoint: "/privatechannel/send",
			Securer:  models.PrivateMessageSecurer,
		},
	)

	// exempt contents are filtered
	m.AddHandler(
		handler.Request{
			Handler:  List,
			Name:     "privatechannel-list",
			Type:     handler.GetRequest,
			Endpoint: "/privatechannel/list",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  Search,
			Name:     "privatechannel-search",
			Type:     handler.GetRequest,
			Endpoint: "/privatechannel/search",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  Count,
			Name:     "privatechannel-count",
			Type:     handler.GetRequest,
			Endpoint: "/privatechannel/count",
		},
	)

	/////////////////////////////////////////
	//    These handlers will be merged    //
	/////////////////////////////////////////
	m.AddHandler(
		handler.Request{
			Handler:  Init,
			Name:     "channel-init-with-participants",
			Type:     handler.PostRequest,
			Endpoint: "/channel/initwithparticipants",
			Securer:  models.PrivateMessageSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  Send,
			Name:     "channel-send-with-participants",
			Type:     handler.PostRequest,
			Endpoint: "/channel/sendwithparticipants",
			Securer:  models.PrivateMessageSecurer,
		},
	)

}
