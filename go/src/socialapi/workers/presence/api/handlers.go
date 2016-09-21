package api

import (
	"errors"
	"net/http"
	"net/url"
	apimodels "socialapi/models"
	"socialapi/workers/common/response"
	"socialapi/workers/presence/models"
	"time"

	"github.com/koding/bongo"
)

// Ping handles the pings coming from client side
//
// TOOD add throttling here
func Ping(u *url.URL, h http.Header, _ interface{}, context *apimodels.Context) (int, http.Header, interface{}, error) {
	// only logged in users can send a ping
	if !context.IsLoggedIn() {
		return response.NewBadRequest(errors.New("not logged in"))
	}

	req := &models.Ping{
		GroupName: context.GroupName,
		AccountID: context.Client.Account.Id, // if client is logged in, those values are all set
		CreatedAt: time.Now().UTC(),
	}

	// send the ping request to the related worker
	if err := bongo.B.PublishEvent(presence.EventName, req); err != nil {
		return response.NewBadRequest(err)
	}

	// send back the updated ping as response
	return response.NewOK(req)
}
