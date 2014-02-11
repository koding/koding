package handlers

import (
	"net/http"
	"net/url"

	"github.com/rcrowley/go-tigertonic"
)

var (
	cors = tigertonic.NewCORSBuilder().AddAllowedOrigins("*")
)

func handlerWrapper(fn func(u *url.URL, h http.Header, rq *Request) (int, http.Header, *Response, error), logName string) http.Handler {
	return cors.Build(
		tigertonic.Timed(
			tigertonic.Marshaled(
				fn,
			),
			logName,
			nil,
		))
}

func Inject(mux *tigertonic.TrieServeMux) *tigertonic.TrieServeMux {
	mux.Handle("POST", "/post", handlerWrapper(post, "create-post"))

	mux.Handle("POST", "/post/{postId}", handlerWrapper(post, "update-post"))

	mux.Handle("POST", "/post/{postId}/like", handlerWrapper(post, "update-post"))
	mux.Handle("DELETE", "/post/{postId}/like/{likeId}", handlerWrapper(post, "update-post"))

	mux.Handle("POST", "/post/{postId}/comment", handlerWrapper(post, "add-comment"))
	mux.Handle("POST", "/post/{postId}/comment/{commentId}", handlerWrapper(post, "update-post-comment"))
	mux.Handle("DELETE", "/post/{postId}/comment/{commentId}", handlerWrapper(post, "delete-post-comment"))

	mux.Handle("GET", "/post/{id}", handlerWrapper(get, "get-post"))
	mux.Handle("GET", "/post/{id}/comments", handlerWrapper(get, "get-post-comments"))
	mux.Handle("GET", "/post/{id}/likes", handlerWrapper(get, "get-post-likes"))

	mux.Handle("POST", "/comment", handlerWrapper(post, "create-comment"))
	mux.Handle("POST", "/comment/{id}", handlerWrapper(post, "update-comment"))
	mux.Handle("GET", "/comment/{id}", handlerWrapper(get, "get-comment"))

	mux.Handle("POST", "/follow/{id}", handlerWrapper(post, "follow-id"))
	mux.Handle("POST", "/unfollow/{id}", handlerWrapper(post, "follow-id"))

	return mux
}

// GET /stuff/{id}
func get(u *url.URL, h http.Header, _ *Request) (int, http.Header, *Response, error) {
	return http.StatusOK, nil, &Response{u.Query().Get("id"), "OK"}, nil
}

func post(u *url.URL, h http.Header, _ *Request) (int, http.Header, *Response, error) {
	return http.StatusAccepted, nil, &Response{"POST", "Accepted"}, nil
}
