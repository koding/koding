package stack

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"

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
}

// LoginResponse represents a response model for "auth.login"
// kloud's kite method.
type LoginResponse struct {
	// ClientID represents a session ID used for
	// authentication with remote.api and Social API.
	ClientID string `json:"clientID"`

	// GroupName is a team name, which we have just logged in to.
	GroupName string `json:"groupName"`
}

// AuthLogin creates a jSession for the given username and team.
//
// If a session already exists, the method is a nop and returns
// already existing one.
//
// TODO(rjeczalik): Add AuthLogout to force creation of a new
// session.
func (k *Kloud) AuthLogin(r *kite.Request) (interface{}, error) {
	k.Log.Debug("auth login called by %q with %q", r.Username, r.Args.Raw)

	req, err := getLoginReq(r)
	if err != nil {
		return nil, err
	}

	ses, err := modelhelper.UserLogin(r.Username, req.GroupName)
	if err != nil {
		return nil, NewError(ErrInternalServer)
	}

	return &LoginResponse{
		ClientID:  ses.ClientId,
		GroupName: req.GroupName,
	}, nil
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
