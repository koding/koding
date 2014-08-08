package api

import (
	"socialapi/workers/common/handler"

	"github.com/rcrowley/go-tigertonic"
)

// TODO wrap this TrieServeMux
func InitHandlers(mux *tigertonic.TrieServeMux) *tigertonic.TrieServeMux {
	mux.Handle("POST", "/trollmode/{accountId}", handler.Wrapper(
		handler.Request{
			Handler: Mark,
			Name:    "trollmode-mark",
		},
	))

	mux.Handle("DELETE", "/trollmode/{accountId}", handler.Wrapper(
		handler.Request{
			Handler: UnMark,
			Name:    "trollmode-unmark",
		},
	))

	return mux
}
