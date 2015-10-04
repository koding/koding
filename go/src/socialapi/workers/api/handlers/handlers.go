package handlers

import (
	"socialapi/workers/api/modules/account"
	"socialapi/workers/api/modules/channel"
	"socialapi/workers/api/modules/client"
	"socialapi/workers/api/modules/interaction"
	"socialapi/workers/api/modules/message"
	"socialapi/workers/api/modules/messagelist"
	"socialapi/workers/api/modules/participant"
	"socialapi/workers/api/modules/pinnedactivity"
	"socialapi/workers/api/modules/popular"
	"socialapi/workers/api/modules/privatechannel"
	"socialapi/workers/api/modules/reply"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"

	"github.com/koding/sshkey"
)

func AddHandlers(m *mux.Mux) {

	account.AddHandlers(m)
	channel.AddHandlers(m)
	client.AddHandlers(m)
	interaction.AddHandlers(m)
	message.AddHandlers(m)
	messagelist.AddHandlers(m)
	participant.AddHandlers(m)
	pinnedactivity.AddHandlers(m)
	popular.AddHandlers(m)
	privatechannel.AddHandlers(m)
	reply.AddHandlers(m)

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
