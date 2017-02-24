package account

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func AddHandlers(m *mux.Mux) {

	m.AddHandler(
		handler.Request{
			Handler:  GetAccountFromSession,
			Name:     "account-info",
			Type:     handler.GetRequest,
			Endpoint: "/account",
		},
	)

	// register an account
	m.AddHandler(
		handler.Request{
			Handler:  Register,
			Name:     "account-create",
			Type:     handler.PostRequest,
			Endpoint: "/account",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  Update,
			Name:     "account-update",
			Type:     handler.PostRequest,
			Endpoint: "/account/{id}",
		},
	)

	// check ownership of an object
	m.AddHandler(
		handler.Request{
			Handler:  CheckOwnership,
			Name:     "account-owns",
			Type:     handler.GetRequest,
			Endpoint: "/account/{id}/owns",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  ListGroupChannels,
			Name:     "account-group-channel-list",
			Type:     handler.GetRequest,
			Endpoint: "/account/channels",
		},
	)
}
