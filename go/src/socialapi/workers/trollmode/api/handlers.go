package api

import (
	"socialapi/workers/common/handler"

	"github.com/rcrowley/go-tigertonic"
)

// TODO wrap this TrieServeMux
func InitHandlers(mux *tigertonic.TrieServeMux) *tigertonic.TrieServeMux {
	mux.Handle(
		"POST",
		"/trollmode/{accountId}",
		handler.Wrapper(Mark, "trollmode-mark", false),
	)
	mux.Handle(
		"DELETE",
		"/trollmode/{accountId}",
		handler.Wrapper(UnMark, "trollmode-unmark", false),
	)

	return mux
}
