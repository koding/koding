package privatechannel

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func AddHandlers(m *mux.Mux) {
	/////////////////////////////////////////
	//    These handlers will be merged    //
	/////////////////////////////////////////
	m.AddHandler(
		handler.Request{
			Handler:  Init,
			Name:     "channel-init-with-participants",
			Type:     handler.PostRequest,
			Endpoint: "/channel/initwithparticipants",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  Send,
			Name:     "channel-send-with-participants",
			Type:     handler.PostRequest,
			Endpoint: "/channel/sendwithparticipants",
		},
	)

}
