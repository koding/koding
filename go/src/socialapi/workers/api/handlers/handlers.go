package handlers

import (
	"net/http"
	"socialapi/workers/api/modules/account"
	"socialapi/workers/api/modules/channel"
	"socialapi/workers/api/modules/interaction"
	"socialapi/workers/api/modules/message"
	"socialapi/workers/api/modules/messagelist"
	"socialapi/workers/api/modules/participant"
	"socialapi/workers/api/modules/reply"

	"github.com/rcrowley/go-tigertonic"
)

var (
	cors = tigertonic.NewCORSBuilder().AddAllowedOrigins("*")
)

func handlerWrapper(handler interface{}, logName string) http.Handler {
	return cors.Build(
		tigertonic.Timed(
			tigertonic.Marshaled(
				handler,
			),
			logName,
			nil,
		))
}

// todo implement context support here for requests
func Inject(mux *tigertonic.TrieServeMux) *tigertonic.TrieServeMux {

	////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////// Message Operations /////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////
	// tested
	mux.Handle("POST", "/message/{id}", handlerWrapper(message.Update, "message-update"))
	// tested
	mux.Handle("DELETE", "/message/{id}", handlerWrapper(message.Delete, "message-delete"))
	// tested
	mux.Handle("GET", "/message/{id}", handlerWrapper(message.Get, "message-get"))

	////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////// Message Reply Operations /////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////
	// tested
	mux.Handle("POST", "/message/{id}/reply", handlerWrapper(reply.Create, "reply-create"))
	// tested
	mux.Handle("DELETE", "/message/{id}/reply/{replyId}", handlerWrapper(reply.Delete, "reply-delete"))
	// tested
	mux.Handle("GET", "/message/{id}/reply", handlerWrapper(reply.List, "reply-list"))

	////////////////////////////////////////////////////////////////////////////////////
	/////////////////////// Message Interaction Operations /////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////
	// add new like
	// tested
	mux.Handle("POST", "/message/{id}/interaction/{type}/add", handlerWrapper(interaction.Add, "interactions-add"))
	// delete like - unlike
	// tested
	mux.Handle("POST", "/message/{id}/interaction/{type}/delete", handlerWrapper(interaction.Delete, "interactions-delete"))
	// get all the interactions for message
	// mux.Handle("GET", "/message/{id}/interaction", handlerWrapper(interaction.List, "interactions-list"))
	// get typed interactions
	// tested
	mux.Handle("GET", "/message/{id}/interaction/{type}", handlerWrapper(interaction.List, "interactions-list-typed"))

	////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////// Channel Operations /////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////
	// tested
	mux.Handle("POST", "/channel", handlerWrapper(channel.Create, "channel-create"))
	// tested
	mux.Handle("POST", "/channel/{id}", handlerWrapper(channel.Update, "channel-update"))
	// tested
	mux.Handle("DELETE", "/channel/{id}", handlerWrapper(channel.Delete, "channel-delete"))
	// tested
	mux.Handle("GET", "/channel/{id}", handlerWrapper(channel.Get, "channel-get"))

	// add a new messages to the channel
	// tested
	mux.Handle("POST", "/channel/{id}/message", handlerWrapper(message.Create, "channel-message-create"))

	// list participants of the channnel
	// tested
	mux.Handle("GET", "/channel/{id}/participant", handlerWrapper(participant.List, "participant-list"))

	// add participant to the channnel
	//tested
	mux.Handle("POST", "/channel/{id}/participant/{accountId}", handlerWrapper(participant.Add, "participant-list"))

	// remove participant from the channel
	// tested
	mux.Handle("DELETE", "/channel/{id}/participant/{accountId}", handlerWrapper(participant.Delete, "participant-list"))

	// list messages of the channel
	mux.Handle("GET", "/channel/{id}/history", handlerWrapper(messagelist.List, "channel-history-list"))

	// list channels of the account
	mux.Handle("GET", "/account/{id}/channels", handlerWrapper(account.ListChannels, "account-channel-list"))

	// follow the account
	mux.Handle("POST", "/account/{id}/follow", handlerWrapper(account.Follow, "account-follow"))
	// mux.Handle("POST", "/follow/{id}", handlerWrapper(post, "follow-id"))
	// mux.Handle("POST", "/unfollow/{id}", handlerWrapper(post, "follow-id"))

	return mux
}

// to-do list
// get current account from context for future
// like client.connection.delegate
