package stack

import "github.com/koding/kite"

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
	// TODO:
	//
	// - use "kd-io" if req.GroupName is empty
	// - check if req.GroupName exists
	// - check whether user belongs to req.GroupName
	// - check whether group's subscription is active
	// - check whether there exists a jSession for {GroupName, Username}
	//   and return clienId if it does
	// - create new jSession and return it's clientId
	//
	return nil, nil
}
