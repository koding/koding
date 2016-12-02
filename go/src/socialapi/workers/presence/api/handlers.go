package api

import (
	"errors"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
	"socialapi/workers/common/response"
	"socialapi/workers/helper"
	"socialapi/workers/presence"
	"time"

	"github.com/koding/bongo"
)

const (
	// EndpointPresencePing provides ping endpoint
	EndpointPresencePing = "/presence/ping"

	// EndpointPresencePingPrivate provides private ping endpoint
	EndpointPresencePingPrivate = "/private/presence/ping"
)

// AddHandlers added the internal handlers to the given Muxer
func AddHandlers(m *mux.Mux) {
	httpRateLimiter := helper.NewDefaultRateLimiter()

	m.AddHandler(
		handler.Request{
			Handler:   Ping,
			Name:      "presence-ping",
			Type:      handler.GetRequest,
			Endpoint:  EndpointPresencePing,
			Ratelimit: httpRateLimiter,
		},
	)
	m.AddHandler(
		handler.Request{
			Handler:   HandlePrivatePing,
			Name:      "presence-ping-private",
			Type:      handler.PostRequest,
			Endpoint:  EndpointPresencePingPrivate,
			Ratelimit: httpRateLimiter,
		},
	)
}

// Ping handles the pings coming from client side
func Ping(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	// only logged in users can send a ping
	if !context.IsLoggedIn() {
		return response.NewBadRequest(errors.New("not logged in"))
	}

	req := &presence.Ping{
		GroupName: context.GroupName,
		AccountID: context.Client.Account.Id, // if client is logged in, those values are all set
	}

	return handlePing(u, h, req)
}

// HandlePrivatePing handles the pings coming from internal services
func HandlePrivatePing(u *url.URL, h http.Header, req *presence.PrivatePing) (int, http.Header, interface{}, error) {
	if req == nil {
		return response.NewBadRequest(errors.New("req should be set"))
	}

	if req.Username == "" {
		return response.NewBadRequest(errors.New("username should be set"))
	}

	acc, err := models.Cache.Account.ByNick(req.Username)
	if err != nil {
		return response.NewBadRequest(err)
	}

	ping := &presence.Ping{
		GroupName: req.GroupName,
		AccountID: acc.Id, // if client is logged in, those values are all set
	}

	return handlePing(u, h, ping)
}

// handlePing handles the pings coming from anywhere
func handlePing(u *url.URL, h http.Header, req *presence.Ping) (int, http.Header, interface{}, error) {
	if req == nil {
		return response.NewBadRequest(errors.New("req should be set"))
	}
	if req.GroupName == "" {
		return response.NewBadRequest(errors.New("groupName should be set"))
	}

	if req.AccountID == 0 {
		return response.NewBadRequest(errors.New("accountId should be set"))
	}

	req.CreatedAt = time.Now().UTC()

	// send the ping request to the related worker
	if err := bongo.B.PublishEvent(presence.EventName, req); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewDefaultOK()
}
