package api

import (
	"errors"
	"net/http"
	"net/url"
	apimodels "socialapi/models"
	"socialapi/workers/collaboration"
	"socialapi/workers/collaboration/models"
	"socialapi/workers/common/response"
	"socialapi/workers/helper"
	"time"

	"github.com/koding/bongo"
)

// Ping handles the pings coming from client side
//
// TOOD add throttling here
func Ping(u *url.URL, h http.Header, req *models.Ping, context *apimodels.Context) (int, http.Header, interface{}, error) {
	// realtime doc id
	if req.FileId == "" {
		return response.NewBadRequest(nil)
	}

	// only logged in users can send a ping
	if !context.IsLoggedIn() {
		return response.NewBadRequest(errors.New("not logged in"))
	}

	// override the account id and set created at
	req.AccountId = context.Client.Account.Id // if client is logged in, those values are all set
	req.CreatedAt = time.Now().UTC()

	// set the last seen at time
	redis := helper.MustGetRedisConn()
	key := collaboration.PrepareFileKey(req.FileId)
	if err := redis.Setex(
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
