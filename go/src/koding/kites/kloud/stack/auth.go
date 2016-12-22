package stack

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	mgo "gopkg.in/mgo.v2"

	"github.com/koding/kite"
)

// LoginRequest represents a request model for "auth.login"
// kloud's kite method.
type LoginRequest struct {
	// GroupName is a team name, which we're going to log in to.
	//
	// If empty, default team is going to be used
	// instead and its name can be read from response value.
	GroupName string `json:"groupName"`

	// Metadata whether
	Metadata bool `json:"metadata,omitempty"`
}

// LoginResponse represents a response model for "auth.login"
// kloud's kite method.
type LoginResponse struct {
	// ClientID represents a session ID used for
	// authentication with remote.api and Social API.
	ClientID string `json:"clientID"`

	// GroupName is a team name, which we have just logged in to.
	GroupName string `json:"groupName"`

	// Username is a name of the user, which we have just logged in as.
	Username string `json:"username"`

	// Metadata represents a Koding configuration, used by client
	// to ensure valid configuration.
	//
	// The field is non-nil, if Metadata in request was true.
	Metadata *Metadata `json:"metadata,omitempty"`
}

// AuthLogin creates a jSession for the given username and team.
//
// If a session already exists, the method is a nop and returns
// already existing one.
//
// TODO(rjeczalik): Add AuthLogout to force creation of a new
// session.
func (k *Kloud) AuthLogin(r *kite.Request) (interface{}, error) {
	k.Log.Debug("AuthLogin called by %q with %q", r.Username, r.Args.Raw)

	req, err := getLoginReq(r)
	if err != nil {
		return nil, err
	}

	ses, err := modelhelper.UserLogin(r.Username, req.GroupName)
	switch err {
	case nil:
	case mgo.ErrNotFound:
		return nil, NewError(ErrBadRequest)
	case modelhelper.ErrNotParticipant:
		return nil, NewError(ErrNotAuthorized)
	default:
		k.Log.Debug("Got generic error for UserLogin, username: %q, err: %q, args: %q", r.Username, err.Error(), r.Args.Raw)
		return nil, NewError(ErrInternalServer)
	}

	if err := k.PresenceClient.Ping(r.Username, req.GroupName); err != nil {
		// we dont need to block user login if there is something wrong with socialapi.
		k.Log.Error("Ping failed with %q for user %q", err.Error(), r.Username)
	}

	resp := &LoginResponse{
		ClientID:  ses.ClientId,
		GroupName: req.GroupName,
		Username:  r.Username,
	}

	if req.Metadata {
		resp.Metadata = &Metadata{
			Endpoints: k.Endpoints,
		}
	}

	return resp, nil
}

func getLoginReq(r *kite.Request) (*LoginRequest, error) {
	if r.Args == nil {
		return nil, NewError(ErrNoArguments)
	}

	var req LoginRequest
	if err := r.Args.One().Unmarshal(&req); err != nil {
		return nil, NewError(ErrBadRequest)
	}

	if req.GroupName == "" {
		req.GroupName = models.KDIOGroupName
	}

	return &req, nil
}
