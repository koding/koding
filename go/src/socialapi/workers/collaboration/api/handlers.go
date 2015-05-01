package api

import (
	"errors"
	"net/http"
	"net/url"
	apimodels "socialapi/models"
	"socialapi/workers/collaboration"
	"socialapi/workers/collaboration/models"
	"socialapi/workers/common/response"
	"time"

	"github.com/koding/bongo"
	"github.com/koding/runner"
)

// Ping handles the pings coming from client side
//
// TOOD add throttling here
func Ping(u *url.URL, h http.Header, req *models.Ping, context *apimodels.Context) (int, http.Header, interface{}, error) {
	if err := validateOperation(req, context); err != nil {
		return response.NewBadRequest(err)
	}

	// set the last seen at time
	key := collaboration.PrepareFileKey(req.FileId)
	if err := runner.MustGetRedisConn().Setex(
		key,
		collaboration.ExpireSessionKeyDuration, // expire the key after this period
		req.CreatedAt.Unix(),                   // value - unix time
	); err != nil {
		return response.NewBadRequest(err)
	}

	// send the ping request to the related worker
	if err := bongo.B.PublishEvent(collaboration.FireEventName, req); err != nil {
		return response.NewBadRequest(err)
	}

	// send back the updated ping as response
	return response.NewOK(req)
}

// End handles the terminate signals coming from client side
func End(u *url.URL, h http.Header, req *models.Ping, context *apimodels.Context) (int, http.Header, interface{}, error) {
	if err := validateOperation(req, context); err != nil {
		return response.NewBadRequest(err)
	}

	key := collaboration.PrepareFileKey(req.FileId)
	// when key is deleted, with the first ping received, collab will be ended
	if _, err := runner.MustGetRedisConn().Del(key); err != nil {
		return response.NewBadRequest(err)
	}

	// send the ping request to the related worker
	if err := bongo.B.PublishEvent(collaboration.FireEventName, req); err != nil {
		return response.NewBadRequest(err)
	}

	// send back the updated ping as response
	return response.NewOK(req)
}

func validateOperation(req *models.Ping, context *apimodels.Context) error {
	// realtime doc id
	if req.FileId == "" {
		return errors.New("fileId not set")
	}

	// only logged in users can send a ping
	if !context.IsLoggedIn() {
		return errors.New("not logged in")
	}

	// override the account id and set created at
	req.AccountId = context.Client.Account.Id // if client is logged in, those values are all set
	req.CreatedAt = time.Now().UTC()

	return collaboration.CanOpen(req)
}
