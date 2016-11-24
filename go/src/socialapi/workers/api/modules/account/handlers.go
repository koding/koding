package account

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func AddHandlers(m *mux.Mux) {
	// added troll mode protection
	// list channels of the account
	m.AddHandler(
		handler.Request{
			Handler:  ListChannels,
			Name:     "account-channel-list",
			Type:     handler.GetRequest,
			Endpoint: "/account/{id}/channels",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  GetAccountFromSession,
			Name:     "account-info",
			Type:     handler.GetRequest,
			Endpoint: "/account",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  ParticipatedChannelCount,
			Name:     "account-channel-list-count",
			Type:     handler.GetRequest,
			Endpoint: "/account/{id}/channels/count",
		},
	)

	// list posts of the account
	m.AddHandler(
		handler.Request{
			Handler:  ListPosts,
			Name:     "account-post-list",
			Type:     handler.GetRequest,
			Endpoint: "/account/{id}/posts",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  FetchPostCount,
			Name:     "account-post-count",
			Type:     handler.GetRequest,
			Endpoint: "/account/{id}/posts/count",
		},
	)

	// follow the account
	m.AddHandler(
		handler.Request{
			Handler:  Follow,
			Name:     "account-follow",
			Type:     handler.PostRequest,
			Endpoint: "/account/{id}/follow",
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

	// un-follow the account
	m.AddHandler(
		handler.Request{
			Handler:  Unfollow,
			Name:     "account-unfollow",
			Type:     handler.PostRequest,
			Endpoint: "/account/{id}/unfollow",
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
