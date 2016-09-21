package api

import (
	"errors"
	"net/http"
	"net/url"
	apimodels "socialapi/models"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
	"socialapi/workers/common/response"
	"socialapi/workers/helper"
	"socialapi/workers/presence"
	"time"

	"github.com/koding/bongo"
)

// AddHandlers added the internal handlers to the given Muxer
func AddHandlers(m *mux.Mux) {
	httpRateLimiter := helper.NewDefaultRateLimiter()

	m.AddHandler(
		handler.Request{
			Handler:   Ping,
			Name:      "presence-ping",
			Type:      handler.GetRequest,
			Endpoint:  "/presence/ping",
			Ratelimit: httpRateLimiter,
		},
	)
}

// Ping handles the pings coming from client side
func Ping(u *url.URL, h http.Header, _ interface{}, context *apimodels.Context) (int, http.Header, interface{}, error) {
	// only logged in users can send a ping
	if !context.IsLoggedIn() {
		return response.NewBadRequest(errors.New("not logged in"))
	}

	req := &presence.Ping{
		GroupName: context.GroupName,
		AccountID: context.Client.Account.Id, // if client is logged in, those values are all set
		CreatedAt: time.Now().UTC(),
	}

	// send the ping request to the related worker
	if err := bongo.B.PublishEvent(presence.EventName, req); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewDefaultOK()
}
