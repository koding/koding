// Package api provides endpoints for realtime handlers
package api

import (
	"errors"
	"fmt"
	"net/http"
	"net/url"
	socialapimodels "socialapi/models"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
	"socialapi/workers/common/response"

	"github.com/koding/bongo"
	"github.com/kr/pretty"
)

// AddHandlers added the internal handlers to the given Muxer
func AddHandlers(m *mux.Mux) {
	m.AddHandler(
		handler.Request{
			Handler:  HandleEvent,
			Name:     socialapimodels.DispatcherEvent,
			Type:     handler.PostRequest,
			Endpoint: "/private/dispatcher/{eventName}",
		},
	)
}

// HandleEvent handles events with given data
func HandleEvent(u *url.URL, h http.Header, req map[string]interface{}) (int, http.Header, interface{}, error) {
	fmt.Printf("u %# v", pretty.Formatter(u))
	fmt.Printf("req %# v", pretty.Formatter(req))

	eventName := u.Query().Get("eventName")
	if eventName == "" {
		return response.NewBadRequest(errors.New("eventName can not be empty"))
	}

	if err := bongo.B.Emit(eventName, req); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewDefaultOK()
}
