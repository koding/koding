package handlers

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"

	"github.com/koding/sshkey"
)

func AddHandlers(m *mux.Mux) {

	// fetch profile feed
	// m.AddHandler("GET", "/account/{id}/profile/feed"
	//   handler.Request{
	//     Handler: account.ListProfileFeed,
	//     Name:    "list-profile-feed",
	//   },
	// )

	m.AddUnscopedHandler(
		handler.Request{
			Handler:  sshkey.Handler,
			Name:     "ssh-key-generator",
			Type:     handler.GetRequest,
			Endpoint: "/sshkey",
		},
	)
}
