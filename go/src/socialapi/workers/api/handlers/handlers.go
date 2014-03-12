package handlers

import (
	"net/http"
	"socialapi/workers/api/modules/channel"
	"socialapi/workers/api/modules/message"
	"socialapi/workers/api/modules/messagelist"
	"socialapi/workers/api/modules/participant"

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

func Inject(mux *tigertonic.TrieServeMux) *tigertonic.TrieServeMux {
	mux.Handle("POST", "/message", handlerWrapper(message.Create, "message-create"))
	mux.Handle("POST", "/message/{id}", handlerWrapper(message.Update, "message-update"))
	mux.Handle("DELETE", "/message/{id}", handlerWrapper(message.Delete, "message-delete"))
	mux.Handle("GET", "/message/{id}", handlerWrapper(message.Get, "message-get"))

	mux.Handle("POST", "/channel", handlerWrapper(channel.Create, "channel-create"))
	mux.Handle("POST", "/channel/{id}", handlerWrapper(channel.Update, "channel-update"))
	mux.Handle("DELETE", "/channel/{id}", handlerWrapper(channel.Delete, "channel-delete"))
	mux.Handle("GET", "/channel/{id}", handlerWrapper(channel.Get, "channel-get"))

	// add participant into a channel
	mux.Handle("POST", "/channel/{id}/participant", handlerWrapper(participant.Add, "participant-add"))

	// remove participant from a channel
	mux.Handle("DELETE", "/channel/{id}/participant", handlerWrapper(participant.Delete, "participant-remove"))

	// list participants of the channnel
	mux.Handle("GET", "/channel/{id}/participant", handlerWrapper(participant.List, "participant-remove"))

	// list messages of the channel
	mux.Handle("GET", "/channel/{id}/history", handlerWrapper(messagelist.List, "channel-history-list"))

	// mux.Handle("POST", "/participant", handlerWrapper(participant.Create, "channel-create"))
	// mux.Handle("POST", "/participant/{id}", handlerWrapper(participant.Update, "channel-update"))
	// mux.Handle("DELETE", "/participant/{id}", handlerWrapper(participant.Delete, "channel-delete"))
	// mux.Handle("GET", "/participant/{id}", handlerWrapper(participant.Get, "channel-get"))

	// mux.Handle("POST", "/post/{postId}/like", handlerWrapper(post, "update-post"))
	// mux.Handle("DELETE", "/post/{postId}/like/{likeId}", handlerWrapper(post, "update-post"))

	// mux.Handle("POST", "/post/{postId}/comment", handlerWrapper(post, "add-comment"))
	// mux.Handle("POST", "/post/{postId}/comment/{commentId}", handlerWrapper(post, "update-post-comment"))
	// mux.Handle("DELETE", "/post/{postId}/comment/{commentId}", handlerWrapper(post, "delete-post-comment"))

	// mux.Handle("GET", "/post/{id}/comments", handlerWrapper(get, "get-post-comments"))
	// mux.Handle("GET", "/post/{id}/likes", handlerWrapper(get, "get-post-likes"))

	// mux.Handle("POST", "/comment", handlerWrapper(post, "create-comment"))
	// mux.Handle("POST", "/comment/{id}", handlerWrapper(post, "update-comment"))
	// mux.Handle("GET", "/comment/{id}", handlerWrapper(get, "get-comment"))

	// mux.Handle("POST", "/follow/{id}", handlerWrapper(post, "follow-id"))
	// mux.Handle("POST", "/unfollow/{id}", handlerWrapper(post, "follow-id"))

	return mux
}

// GET /stuff/{id}
// func get(u *url.URL, h http.Header, _ *Request) (int, http.Header, *Response, error) {
// 	return http.StatusOK, nil, &Response{u.Query().Get("id"), "OK"}, nil
// }

// func post2(u *url.URL, h http.Header, _ *Request) (int, http.Header, *Response, error) {
// 	return http.StatusAccepted, nil, &Response{"POST", "Accepted"}, nil
// }
